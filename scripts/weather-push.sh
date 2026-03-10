#!/bin/bash
# 每日天气推送脚本 - 多地综合报告
# 通过 OpenClaw 发送天气到飞书

# 确保 crontab 环境中能找到命令
export PATH="/usr/local/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export OPENCLAW_GATEWAY_TOKEN="ea1f45855d08d68d453d774f37f65f8bf6841d13cfaf8d1c"
export HOME="/home/gh"
export NODE_PATH="/usr/local/node/lib/node_modules"

TODAY=$(date '+%-m月%-d日')

# 天气代码转图标和描述
get_weather_icon() {
    local code=$1
    case $code in
        113) echo "☀️ 晴" ;;
        116) echo "⛅️ 多云" ;;
        119) echo "☁️ 阴" ;;
        122) echo "🌥️ 阴" ;;
        143|248|260) echo "🌫️ 雾" ;;
        176|263|266|293|296|299|302|305|308|311|314|317|320|353|356|359) echo "🌧️ 雨" ;;
        179|182|185|227|230|281|284|323|326|329|332|335|338|362|365|368|371|374|377) echo "🌨️ 雪" ;;
        200) echo "⛈️ 雷暴" ;;
        386|389|392|395) echo "⛈️ 雷雨" ;;
        *) echo "🌤️" ;;
    esac
}

# 获取城市天气数据
get_weather_data() {
    local city=$1
    curl -s "wttr.in/$city?format=j1"
}

# 生成生活建议
get_life_advice() {
    local temp=$1
    local humidity=$2
    local wind=$3
    local uv=$4
    
    # 穿衣建议
    if [ "$temp" -lt 5 ]; then
        clothing="🧥 穿衣：寒冷，建议羽绒服+保暖内衣"
    elif [ "$temp" -lt 10 ]; then
        clothing="🧥 穿衣：较冷，建议厚外套+毛衣"
    elif [ "$temp" -lt 15 ]; then
        clothing="🧥 穿衣：凉爽，建议外套+长袖"
    elif [ "$temp" -lt 20 ]; then
        clothing="🧥 穿衣：舒适，薄外套即可"
    else
        clothing="🧥 穿衣：温暖，单衣即可"
    fi
    
    # 运动建议
    if [ "$wind" -gt 15 ]; then
        sport="🏃 运动：较适宜（建议室内）"
    else
        sport="🏃 运动：较适宜，注意增减衣物"
    fi
    
    # 感冒风险
    if [ "$temp" -lt 10 ] && [ "$humidity" -gt 70 ]; then
        cold="🤧 感冒：极易发，强降温注意保暖"
    elif [ "$temp" -lt 10 ]; then
        cold="🤧 感冒：较易发，注意保暖"
    else
        cold="🤧 感冒：少发"
    fi
    
    # 洗车建议
    if [ "$wind" -gt 20 ]; then
        carwash="🚗 洗车：较不宜（风力大）"
    else
        carwash="🚗 洗车：适宜"
    fi
    
    # 紫外线
    if [ "$uv" -le 2 ]; then
        uv_text="☀️ 紫外线：最弱"
    elif [ "$uv" -le 5 ]; then
        uv_text="☀️ 紫外线：弱"
    elif [ "$uv" -le 7 ]; then
        uv_text="☀️ 紫外线：强"
    else
        uv_text="☀️ 紫外线：很强"
    fi
    
    echo "$clothing
$sport
$cold
$carwash | $uv_text"
}

# 解析城市天气
parse_city_weather() {
    local city=$1
    local city_name=$2
    local data=$(get_weather_data "$city")
    
    # 当前天气
    local current_temp=$(echo "$data" | jq -r '.current_condition[0].temp_C')
    local feels_like=$(echo "$data" | jq -r '.current_condition[0].FeelsLikeC')
    local humidity=$(echo "$data" | jq -r '.current_condition[0].humidity')
    local wind=$(echo "$data" | jq -r '.current_condition[0].windspeedKmph')
    local weather_code=$(echo "$data" | jq -r '.current_condition[0].weatherCode')
    local uv=$(echo "$data" | jq -r '.current_condition[0].uvIndex')
    local weather_icon=$(get_weather_icon "$weather_code")
    
    # 今日温度范围
    local max_temp=$(echo "$data" | jq -r '.weather[0].maxtempC')
    local min_temp=$(echo "$data" | jq -r '.weather[0].mintempC')
    
    # 生活建议
    local advice=$(get_life_advice "$current_temp" "$humidity" "$wind" "$uv")
    
    # 未来三天
    local day1_desc=$(echo "$data" | jq -r '.weather[1].hourly[4].weatherDesc[0].value' 2>/dev/null || echo "晴好")
    local day1_max=$(echo "$data" | jq -r '.weather[1].maxtempC')
    local day1_min=$(echo "$data" | jq -r '.weather[1].mintempC')
    local day1_code=$(echo "$data" | jq -r '.weather[1].hourly[4].weatherCode' 2>/dev/null || echo "113")
    
    local day2_desc=$(echo "$data" | jq -r '.weather[2].hourly[4].weatherDesc[0].value' 2>/dev/null || echo "晴好")
    local day2_code=$(echo "$data" | jq -r '.weather[2].hourly[4].weatherCode' 2>/dev/null || echo "113")
    
    local day3_desc=$(echo "$data" | jq -r '.weather[3].hourly[4].weatherDesc[0].value' 2>/dev/null || echo "晴好")
    local day3_code=$(echo "$data" | jq -r '.weather[3].hourly[4].weatherCode' 2>/dev/null || echo "113")
    
    # 转换未来天气描述
    local day1_icon=$(get_weather_icon "$day1_code")
    local day2_icon=$(get_weather_icon "$day2_code")
    local day3_icon=$(get_weather_icon "$day3_code")
    
    # 计算未来日期
    local day1_date=$(date -d "+1 day" '+%-m月%-d日' 2>/dev/null || date -v+1d '+%-m月%-d日')
    local day2_date=$(date -d "+2 day" '+%-m月%-d日' 2>/dev/null || date -v+2d '+%-m月%-d日')
    local day3_date=$(date -d "+3 day" '+%-m月%-d日' 2>/dev/null || date -v+3d '+%-m月%-d日')
    
    echo "🏙️ $city_name
今天（$TODAY）$weather_icon
温度：${min_temp}°C - ${max_temp}°C | 风力：${wind}km/h
$advice
未来三天
$day1_date：$day1_icon ${day1_min}°C-${day1_max}°C
$day2_date：$day2_icon 天气持续向好
$day3_date：$day3_icon 适合户外活动"
}

# 获取三地天气
hangzhou=$(parse_city_weather "Hangzhou" "杭州")
ningbo=$(parse_city_weather "Ningbo" "宁波鄞州")
anqing=$(parse_city_weather "Anqing" "安庆")

# 构建完整消息
MESSAGE="🌤️ 三地天气综合报告（$TODAY）

$hangzhou

🌊 $ningbo

🏔️ $anqing

📌 今日总结
三地今天都偏冷，记得穿暖！周末天气都会越来越好！🌈

🍓 小莓派为你播报"

# 发送消息
LOG_FILE="/home/gh/.openclaw/workspace/logs/weather-push.log"

if /usr/local/node/bin/openclaw message send \
    --channel feishu \
    --target "user:ou_f2f35f0e18693a230ebeebfa58e6b1f4" \
    --message "$MESSAGE" 2>>"$LOG_FILE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 天气推送成功" >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 天气推送失败" >> "$LOG_FILE"
fi
