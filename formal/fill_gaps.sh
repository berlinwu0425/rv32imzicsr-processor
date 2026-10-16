#!/bin/bash
cd ~/formal_verify
run() {  # 模型前綴 範本 D F 第三參數名 值 深度(空白=沿用範本)
  local t=$5; [ "$t" = L_LAT ] && t=L
  local n=${1}_D${3}_F${4}_${t}${6}
  sed -e "s/-set D [0-9]*/-set D $3/" -e "s/-set F [0-9]*/-set F $4/" -e "s/-set $5 [0-9]*/-set $5 $6/" $2 > $n.sby
  [ -n "$7" ] && sed -i "s/^depth .*/depth $7/" $n.sby
  grep -Eq -- "-set D $3 -set F $4 -set $5 $6( |$)" $n.sby || { echo "$n 參數沒改到，跳過"; return; }
  sby -f $n.sby > /dev/null 2>&1
  local r=$( [ -f $n/PASS ] && echo PASS || { [ -f $n/FAIL ] && echo FAIL || echo UNKNOWN; } )
  local e=$( [ $4 -le $(( $3 + 1 + $6 )) ] && echo PASS || echo FAIL )
  [ "$r" = "$e" ] && m=OK || m="<<< 不一致"
  echo "$n 結果=$r 預期=$e $m"
}
echo "===== 4.8 附錄 D 交界點（depth 24）====="
run bstall bstall_D0_F7_S3.sby 8 11 S 1 24
run bstall bstall_D0_F7_S3.sby 7 11 S 2 24
run bstall bstall_D0_F7_S3.sby 6 11 S 3 24
run bstall bstall_D0_F7_S3.sby 8 11 S 2 24
run bstall bstall_D0_F7_S3.sby 8 12 S 2 24
run bstall bstall_D0_F7_S3.sby 7 11 S 3 24
run bstall bstall_D0_F7_S3.sby 7 12 S 3 24
run bstall bstall_D0_F7_S3.sby 8 12 S 3 24
run bstall bstall_D0_F7_S3.sby 8 13 S 3 24
echo "===== 4.7 缺的 2 個點 ====="
run kill kill_D2_F6_L4.sby 7 11 L_LAT 2 ""
run kill kill_D2_F6_L4.sby 5 11 L_LAT 4 ""
echo "===== 主掃描組數清點（範圍內）====="
ALL=$( { ls -d */ *.sby 2>/dev/null; cat *.csv 2>/dev/null; } )
echo "4.6 boundary：$(echo "$ALL" | grep -oE 'boundary_D[0-8]_F([0-9]|10)\b' | sort -u | wc -l)（應為 99）"
echo "4.7 kill    ：$(echo "$ALL" | grep -oE 'kill_D[0-8]_F([0-9]|10)_L[024]\b' | sort -u | wc -l)（應為 297）"
echo "4.8 bstall  ：$(echo "$ALL" | grep -oE 'bstall_D[0-8]_F([0-9]|10)_S[0-3]\b' | sort -u | wc -l)（應為 396）"
E=$(echo "$ALL" | grep -oE 'equiv_D[0-9]+_F[0-9]+_L[0-9]+' | sort -u)
echo "4.7 equiv（safety+liveness）：$(echo "$E" | grep -c .) 組"
echo "  D 值：$(echo "$E" | sed -E 's/.*_D([0-9]+)_.*/\1/' | sort -nu | tr '\n' ' ')"
echo "  F 值：$(echo "$E" | sed -E 's/.*_F([0-9]+)_.*/\1/' | sort -nu | tr '\n' ' ')"
echo "  L 值：$(echo "$E" | sed -E 's/.*_L([0-9]+)/\1/' | sort -nu | tr '\n' ' ')"
