#!/bin/bash
# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# Download Azur Lane

echo "Get Azur Lane apk"

    # eg: wget "your download link" -O "your packge name.apk" -q
    #if you want to patch .xapk, change the suffix here to wget "your download link" -O "your packge name.xapk" -q
7z x com.bilibili.AzurLane.zip
echo "apk downloaded !"

    # if you can only download .xapk file uncomment 2 lines below. (delete the '#')
    #unzip -o com.YoStarJP.AzurLane.xapk -d AzurLane
    #cp AzurLane/com.YoStarJP.AzurLane.apk .


# Download JMBQ
if [ ! -d "azurlane" ]; then
    echo "download JMBQ"
    git clone https://github.com/feathers-l/azurlane
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar d -q -f com.bilibili.AzurLane.apk

echo "Copy JMBQ libs"
cp -r azurlane/{lib,smali_classes4} com.bilibili.AzurLane/

echo "Patching Azur Lane with JMBQ"
cp ComponentActivity.smali com.bilibili.AzurLane/smali/androidx/core/app/
cp AndroidManifest.xml com.bilibili.AzurLane/


echo "Build Patched Azur Lane apk"
java -jar apktool.jar b -q -f com.bilibili.AzurLane -o build/com.bilibili.AzurLane.patched.apk

echo "Set Github Release version"
s=($(./apkeep -a com.bilibili.AzurLane -l .))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
