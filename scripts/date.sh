SEC=$(date "+%s")
MIN=$(expr $((SEC)) / 60)
echo ::set-env name=DATE_VERSION::$MIN