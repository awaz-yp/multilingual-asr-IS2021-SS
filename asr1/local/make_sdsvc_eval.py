#!/usr/bin/env python

import argparse
import locale
import os
import sys
import traceback
import re

locale.setlocale(locale.LC_ALL, "C")


def get_args():
    """ Get args from stdin.
    """

    parser = argparse.ArgumentParser(
        description="""Prepare a data directory for using in Kaldi for Speaker recognition.""",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        conflict_handler='resolve')

    parser.add_argument("--task", type=str, dest='task', choices=["task1", "task2"],
                        help="Shows the interesting task. It can be task1 or task2.", required=True)

    parser.add_argument("--task-root-dir", type=str, dest='task_root_dir', required=True,
                        help="Shows the main directory of the task which contains all raw files and docs.")

    parser.add_argument("--check-file-exist", type=str, dest='check_file_exist', choices=["yes", "no"],
                        help="Check whether file exit or not to included to the output file.", default="no")

    parser.add_argument("--data-dir", type=str, dest="data_dir", default='data',
                        help="Path to the Kaldi data directory. Two separate directory will be created in"
                             "this directory.")

    # print(' '.join(sys.argv))

    args = parser.parse_args()

    args = process_args(args)

    return args


def process_args(args):
    """ Process the options got from get_args()
    """
    args.task_root_dir = args.task_root_dir.strip()
    if args.task_root_dir[-1] != '/':
        args.task_root_dir += '/'
    if args.task_root_dir == '' or not os.path.exists(args.task_root_dir):
        raise Exception("This scripts expects the task root directory exist: {0}".format(args.task_root_dir))

    for name in ['docs/model_enrollment.txt', 'docs/trials.txt']:
        if not os.path.exists(os.path.join(args.task_root_dir, name)):
            raise Exception("This scripts expects following file exist: {0}".
                            format(os.path.join(args.task_root_dir, name)))

    args.check_file_exist = args.check_file_exist == 'yes'

    if not os.path.exists(args.data_dir):
        os.makedirs(args.data_dir)

    return args


def yield_lines(file_path, skipped_line_count=0):
    """
    This function read a file line by line and yelds non-empty lines.
    :param file_path: input file to be read
    :param skipped_line_count: shows number of header line which should be skipped
    """
    with open(file_path, "rt") as fid:
        i = 0
        for line in fid:
            i += 1
            if i <= skipped_line_count:
                continue
            _line = re.sub("[\r\n]", "", line)
            if len(_line) > 0:
                yield _line


def make(args):
    print('Start creating data dir for SdSV Challenge %s' % args.task)

    task = args.task
    is_task1 = task == 'task1'
    task_root_di = args.task_root_dir
    data_dir = args.data_dir

    model_enrollment = os.path.join(task_root_di, 'docs/model_enrollment.txt')
    trial_file = os.path.join(task_root_di, 'docs/trials.txt')
    key_file = os.path.join(task_root_di, 'keys.txt')
    if os.path.exists(key_file):
        keys = yield_lines(key_file, skipped_line_count=1)
    else:
        keys = None

    output_dir = os.path.join(data_dir, 'sdsv_challenge_%s.enroll' % task)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    utt2spk = open(os.path.join(output_dir, 'utt2spk'), 'wt')
    wav_scp = open(os.path.join(output_dir, 'wav.scp'), 'wt')

    for line in yield_lines(model_enrollment, skipped_line_count=1):
        parts = line.split(' ')
        model_id = parts[0]
        start_idx = 2 if is_task1 else 1
        for i in range(start_idx, len(parts)):
            wav_path = os.path.join(task_root_di, 'wav/enrollment', parts[i] + '.wav')
            if args.check_file_exist and not os.path.exists(wav_path):
                print('Warning: file not exist. %s' % wav_path)
                continue
            wav_scp.write('{0}-{1} {2}\n'.format(model_id, parts[i], wav_path))
            utt2spk.write("{0}-{1} {0}\n".format(model_id, parts[i]))
    utt2spk.close()
    wav_scp.close()

    if os.system("utils/utt2spk_to_spk2utt.pl {out_dir}/utt2spk > {out_dir}/spk2utt".format(out_dir=output_dir)) != 0:
        raise Exception("Error creating spk2utt file in directory {out_dir}".format(out_dir=output_dir))

    if os.system("utils/fix_data_dir.sh {out_dir}".format(out_dir=output_dir)) != 0:
        raise Exception("Error fixing data dir {out_dir}".format(out_dir=output_dir))

    output_dir = os.path.join(data_dir, 'sdsv_challenge_%s.test' % task)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    trials = open(os.path.join(output_dir, 'trials'), 'wt')
    test_files = set()
    if keys is None:
        entries = yield_lines(trial_file, skipped_line_count=1)
    else:
        entries = zip(yield_lines(trial_file, skipped_line_count=1), keys)
    for entry in entries:
        if keys is None:
            parts = entry.split(' ')
            target_type = 'unknown'
        else:
            parts = entry[0].split(' ') + entry[1].split(' ')
            if is_task1:
                if parts[2] == 'TC':
                    target_type = 'target'
                else:
                    target_type = 'nontarget'
            else:
                if parts[2] == 'tgt':
                    target_type = 'target'
                else:
                    target_type = 'nontarget'
        test_files.add(parts[1])
        trials.write('{spk} {utt} {target_type}\n'.format(spk=parts[0], utt=parts[1], target_type=target_type))
    trials.close()

    test_files = list(test_files)
    test_files.sort()

    utt2spk = open(os.path.join(output_dir, 'utt2spk'), 'wt')
    spk2utt = open(os.path.join(output_dir, 'spk2utt'), 'wt')
    wav_scp = open(os.path.join(output_dir, 'wav.scp'), 'wt')

    for name in test_files:
        wav_path = os.path.join(task_root_di, 'wav/evaluation', name + '.wav')
        if args.check_file_exist and not os.path.exists(wav_path):
            print('Warning: file not exist. %s' % wav_path)
            continue
        wav_scp.write('{0} {1}\n'.format(name, wav_path))
        utt2spk.write("{0} {0}\n".format(name))
        spk2utt.write("{0} {0}\n".format(name))
    utt2spk.close()
    spk2utt.close()
    wav_scp.close()

    if os.system("utils/fix_data_dir.sh {out_dir}".format(out_dir=output_dir)) != 0:
        raise Exception("Error fixing data dir {out_dir}".format(out_dir=output_dir))


def main():
    args = get_args()
    try:
        make(args)
    except BaseException as e:
        # look for BaseException so we catch KeyboardInterrupt, which is
        # what we get when a background thread dies.
        if not isinstance(e, KeyboardInterrupt):
            traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
