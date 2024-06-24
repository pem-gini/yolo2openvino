#!/bin/bash


PATH_PREFIX=$1

if [ -z "$PATH_PREFIX" ]
then
    PATH_PREFIX=$CONDA_PREFIX
fi

mkdir -p output_dir
rm output_dir/*

### temporarily create classnames files
echo "fist
like
ok
palm
peace
peace_inv
stop" > classnames.tmp.txt



# INPUTDATATYPE="FP16"
INPUTDATATYPE="FP16"
 
### conversion to tf
python convert_weights_pb.py --yolo 4 --tiny  --weights_file yolov4-tiny-custom_best.weights --class_names classnames.tmp.txt --output output_dir/yolov4tiny.pb -h 416 -w 416 -a 10,14,23,27,37,58,81,82,135,169,344,319

### conversion to openvino
$PATH_PREFIX/bin/mo \
--input_model output_dir/yolov4tiny.pb \
--tensorflow_use_custom_operations_config json/GESTURES_yolo_v4_tiny.json \
--batch 1 \
--data_type $INPUTDATATYPE \
--reverse_input_channels \
--layout "nhwc->nchw" \
--model_name yolov4tiny \
--output_dir output_dir/
###
###!!!!!! --layout  is necessary since openvino 2022.1 since the input order was changed to nhwc (which means the camera will think that the nn input is 3xwidth instead of withdxheight)
### see https://discuss.luxonis.com/d/1196-neuralnetwork0-warning-input-image-224x224-does-not-match-nn-3x224/22

rm classnames.tmp.txt

### compile to blob for inference on OAK devices using blobconverter api (which internally also uses depthai web app)
###https://blobconverter.luxonis.com/
$PATH_PREFIX/bin/blobconverter \
-v 2022.1 \
--shaves 6 \
--no-cache \
--data-type $INPUTDATATYPE \
-ox output_dir/yolov4tiny.xml \
-ob output_dir/yolov4tiny.bin \
-o output_dir 

#--compile-params "ipU8" \

#### compile to blob using openvino toolkit locally
# ./compile_tool -m output_dir/yolov4tiny.xml -d MYRIAD


