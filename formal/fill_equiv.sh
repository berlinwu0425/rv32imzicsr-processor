#!/bin/bash
cd ~/formal_verify
T=equiv_D2_F6_L4.sby
ok=0; bad=0; skip=0; out=equiv_full_results.csv
echo "name,result,expected" > $out
one() {  # D F L
  local n=equiv_D$1_F$2_L$3
  if [ -f $n/PASS ] || [ -f $n/FAIL ]; then
    skip=$((skip+1)); r=$( [ -f $n/PASS ] && echo PASS || echo FAIL )
  else
    sed -e "s/-set D [0-9]*/-set D $1/" -e "s/-set F [0-9]*/-set F $2/" \
        -e "s/-set L_LAT [0-9]*/-set L_LAT $3/" -e "s/^depth .*/depth 24/" $T > $n.sby
    grep -Eq -- "-set D $1 -set F $2 -set L_LAT $3( |$)" $n.sby || { echo "$n 參數沒改到"; bad=$((bad+1)); return; }
    sby -f $n.sby > /dev/null 2>&1
    r=$( [ -f $n/PASS ] && echo PASS || { [ -f $n/FAIL ] && echo FAIL || echo UNKNOWN; } )
  fi
  e=$( [ $2 -le $(( $1 + 1 + $3 )) ] && echo PASS || echo FAIL )
  echo "$n,$r,$e" >> $out
  if [ "$r" = "$e" ]; then ok=$((ok+1)); else bad=$((bad+1)); echo "<<< 不一致：$n 結果=$r 預期=$e"; fi
}
for D in $(seq 0 8); do
  for F in $(seq 0 10); do for L in 0 2 4; do one $D $F $L; done; done
  echo "D=$D 完成"
done
echo "--- 4.7 邊界外交界點 ---"
for p in "7 11 2" "8 11 2" "8 12 2" "5 11 4" "6 11 4" "6 12 4" "7 12 4" "7 13 4" "8 13 4" "8 14 4"; do one $p; done
echo "===== 完成：一致 $ok、不一致 $bad（沿用既有結果 $skip 組）====="
