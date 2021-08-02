## TCS Submission for MUCS challenge

* asr1 contains recipe for ESPNet system
* s5 contains recipe for kaldi system

## ESPNet System Training
* Install ESPNet (commit 53f6aa11d8702c76fc3220ca94ea279a11dbcf19) and move asr1 as `espnet/egs/MUCS/asr1`
* cd to `espnet/egs/MUCS/asr1`
* Checkout `run.sh` and run it after changing path to dataset

## Kaldi System Training
* Install kaldi and move s5 as `kaldi/egs/MUCS/s5`
* cd to `kaldi/egs/MUCS/s5`
* Checkout `run.sh` and run it after changing path to dataset

## Evaluate pre-trained system
* The pre-trained model and instructions to run can be found [here](https://drive.google.com/file/d/1ZSn1nMS7CVBFHweiu9UUtVUJaMklkAyo/view?usp=sharing)
* System description can be found [here](https://drive.google.com/file/d/1n1fT2kgvBw0Veeni3SlGS90Rglm5zmZV/view?usp=sharing)
