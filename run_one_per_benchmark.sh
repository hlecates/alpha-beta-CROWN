#!/bin/sh
# Run one instance from each benchmark and log results

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CD_DIR="$SCRIPT_DIR/complete_verifier"
CONFIG="exp_configs/abCROWN_experiments.yaml"
BENCH_DIR="$SCRIPT_DIR/benchmarks"
LOG_FILE="$SCRIPT_DIR/benchmark_results.log"

echo "========================================" | tee "$LOG_FILE"
echo "Benchmark Test Run - $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

PASS=0
FAIL=0
TOTAL=18

run_bench() {
  bench="$1"
  onnx="$2"
  vnnlib="$3"
  onnx_path="$BENCH_DIR/$bench/$onnx"
  vnnlib_path="$BENCH_DIR/$bench/$vnnlib"

  echo "" | tee -a "$LOG_FILE"
  echo "----------------------------------------" | tee -a "$LOG_FILE"
  echo "Benchmark: $bench" | tee -a "$LOG_FILE"
  echo "  ONNX:   $onnx" | tee -a "$LOG_FILE"
  echo "  VNNLib: $vnnlib" | tee -a "$LOG_FILE"
  echo "----------------------------------------" | tee -a "$LOG_FILE"

  if [ ! -f "$onnx_path" ]; then
    echo "  SKIP - ONNX file not found: $onnx_path" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
    return
  fi
  if [ ! -f "$vnnlib_path" ]; then
    echo "  SKIP - VNNLib file not found: $vnnlib_path" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
    return
  fi

  cd "$CD_DIR"
  output=$(python abcrown.py --config "$CONFIG" \
    --onnx_path "$onnx_path" \
    --vnnlib_path "$vnnlib_path" 2>&1)
  exit_code=$?

  result_line=$(echo "$output" | grep "^Result:" | tail -1)
  time_line=$(echo "$output" | grep "^Time:" | tail -1)

  if [ $exit_code -eq 0 ]; then
    echo "  STATUS: SUCCESS (exit code 0)" | tee -a "$LOG_FILE"
    PASS=$((PASS + 1))
  else
    echo "  STATUS: FAILED (exit code $exit_code)" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
  fi
  echo "  $result_line" | tee -a "$LOG_FILE"
  echo "  $time_line" | tee -a "$LOG_FILE"

  if [ $exit_code -ne 0 ]; then
    error_lines=$(echo "$output" | grep -i "error\|traceback\|exception" | tail -3)
    echo "  ERRORS: $error_lines" | tee -a "$LOG_FILE"
  fi
}

run_bench "acasxu_2023" "onnx/ACASXU_run2a_1_1_batch_2000.onnx" "vnnlib/prop_1.vnnlib"
run_bench "cctsdb_yolo_2023" "onnx/patch-1.onnx" "vnnlib/spec_onnx_patch-1_idx_00559_0.vnnlib"
run_bench "cersyve" "onnx/lane_keep_pretrain_con.onnx" "vnnlib/prop_lane_keep.vnnlib"
run_bench "cgan_2023" "onnx/cGAN_imgSz32_nCh_1.onnx" "vnnlib/cGAN_imgSz32_nCh_1_prop_0_input_eps_0.010_output_eps_0.015.vnnlib"
run_bench "cifar100_2024" "onnx/CIFAR100_resnet_medium.onnx" "vnnlib/CIFAR100_resnet_medium_prop_idx_7641_sidx_1041_eps_0.0039.vnnlib"
run_bench "collins_rul_cnn_2022" "onnx/NN_rul_small_window_20.onnx" "vnnlib/robustness_2perturbations_delta5_epsilon10_w20.vnnlib"
run_bench "cora_2024" "onnx/mnist-point.onnx" "vnnlib/mnist-img0.vnnlib"
run_bench "dist_shift_2023" "onnx/mnist_concat.onnx" "vnnlib/index7901_delta0.13.vnnlib"
run_bench "linearizenn_2024" "onnx/AllInOne_10_10.onnx" "vnnlib/prop_10_10.vnnlib"
run_bench "malbeware" "onnx/malware_malimg_family_scaled_linear-25.onnx" "vnnlib/malbeware_family-Obfuscator.AD_label-17_eps-1_idx-89.vnnlib"
run_bench "metaroom_2023" "onnx/6cnn_tz_35_5_no_custom_OP.onnx" "vnnlib/spec_idx_176_eps_0.00001000.vnnlib"
run_bench "nn4sys" "onnx/pensieve_small_simple.onnx" "vnnlib/pensieve_simple_0.vnnlib"
run_bench "safenlp_2024" "onnx/medical/perturbations_0.onnx" "vnnlib/medical/hyperrectangle_418.vnnlib"
run_bench "sat_relu" "onnx/sat_v30_c38.onnx" "vnnlib/sat_v30_c38.vnnlib"
run_bench "soundnessbench" "onnx/model.onnx" "vnnlib/model_0.vnnlib"
run_bench "test" "onnx/test_nano.onnx" "vnnlib/test_nano.vnnlib"
run_bench "tinyimagenet_2024" "onnx/TinyImageNet_resnet_medium.onnx" "vnnlib/TinyImageNet_resnet_medium_prop_idx_1126_sidx_4974_eps_0.0039.vnnlib"
run_bench "tllverifybench_2023" "onnx/tllBench_n=2_N=M=8_m=1_instance_0_0.onnx" "vnnlib/property_N=8_0.vnnlib"

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "SUMMARY: $PASS/$TOTAL passed, $FAIL/$TOTAL failed" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "Full log saved to: $LOG_FILE"
