#!/bin/bash
cd ~/formal_verify
SUMMARY=~/formal_verify/extend_final_gaps_results.csv
echo "section,D,F,param,expected,actual,match" > "$SUMMARY"

run_one() {
  local dir=$1 model=$2 mode=$3 chparam=$4 depth=$5 expected=$6 label=$7
  if [ -f "$dir/config.sby" ] || [ -f "$dir.sby" ]; then
    return
  fi
  mkdir -p "$dir"
  cat > "$dir/config.sby" << EOF
[options]
mode $mode
depth $depth

[engines]
smtbmc z3

[script]
read -formal -DFORMAL ${model}.v
chparam -set $chparam $model
prep -top $model

[files]
../rtl/${model}.v
EOF
  out=$(sby -f "$dir/config.sby" 2>&1 || true)
  if echo "$out" | grep -q "DONE (PASS"; then actual="PASS"
  elif echo "$out" | grep -q "DONE (FAIL"; then actual="FAIL"
  else actual="UNKNOWN"; fi
  match="OK"; [ "$actual" != "$expected" ] && match="MISMATCH!!"
  echo "$label,$expected,$actual,$match" >> "$SUMMARY"
  [ "$match" = "MISMATCH!!" ] && echo ">>> $label 預期=$expected 實際=$actual <<<"
}

echo "===== 缺口一：4.8節 D=0,1 補到 F=10 ====="
for D in 0 1; do
  for S in 0 1 2 3; do
    for F in 8 9 10; do
      bound=$((D+1+S))
      depth=$(( (bound>F?bound:F) + 5 ))
      exp="PASS"; [ $F -gt $bound ] && exp="FAIL"
      run_one "bstall_D${D}_F${F}_S${S}" "bounded_stall_model" "bmc" "D $D -set F $F -set S $S" "$depth" "$exp" "4.8,D=$D,F=$F,S=$S"
    done
  done
done

echo "===== 缺口二：4.7節 4組邊界值 ====="
declare -a combos=("6 4 11" "6 4 12" "7 4 12" "7 4 13" "8 4 13" "8 4 14" "8 2 11" "8 2 12")
for c in "${combos[@]}"; do
  read D L F <<< "$c"
  bound=$((D+1+L))
  depth=$(( (bound>F?bound:F) + 4 ))
  exp="PASS"; [ $F -gt $bound ] && exp="FAIL"
  run_one "kill_D${D}_F${F}_L${L}" "speculative_kill_model" "prove" "D $D -set F $F -set L_LAT $L" "$depth" "$exp" "4.7,D=$D,F=$F,L=$L"
done

echo ""
echo "===== 完成 ====="
echo "MISMATCH 數量：$(grep -c MISMATCH "$SUMMARY" || echo 0)"
echo "UNKNOWN 數量：$(grep -c UNKNOWN "$SUMMARY" || echo 0)"
