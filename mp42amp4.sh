#!/bin/bash

input_video="Oogachaka_Baby.mp4"

cwd=$(pwd)

# get fps
fps=$(ffmpeg -i $cwd/$input_video 2>&1 | grep "Stream #0:0" | grep -Eo '[0-9]+ fps' | cut -d ' ' -f 1)

# usefull stuff
#ascii_res=50x50
#a_h=50
#a_w=50


tmp_dir=$(mktemp -d)
#echo $tmp_dir
#
# Step 0: Extract sound
ffmpeg -i $input_video -vn -acodec copy $tmp_dir/audio.aac


# Step1: Extract Images
mkdir $tmp_dir/extracted_frames
ffmpeg -i $cwd/$input_video -vf "fps=$fps" $tmp_dir/extracted_frames/%04d.jpg 

dimensions=$(identify -format "%wx%h" "$tmp_dir/extracted_frames/$(ls $tmp_dir/extracted_frames/ | grep '.jpg' | head -n 1)")
# Extract width and height from dimensions
width=$(echo "$dimensions" | cut -d'x' -f1)
height=$(echo "$dimensions" | cut -d'x' -f2)

# Multiply width and height by ten
new_width=$(($width *6))
new_height=$(($height *6))


a_w=$(($width / 2))
a_h=$(($height / 2))


# Step 2: convert Images to ASCII
mkdir $tmp_dir/ascii_images
for file in $tmp_dir/extracted_frames/*.jpg; do
	jp2a --size="${a_w}x${a_h}" "$file" > "$tmp_dir/ascii_images/$(basename $file).txt"
done

# alignement of convert:
for file in $tmp_dir/ascii_images/*.txt; do
    # Replace the first character of each file with a .
    sed -i '1s/^/./' "$file"
done



# Step 3: Convert ASCII Images Back to Images
#cd $tmp_dir/ascii_images
mkdir $tmp_dir/output_images
for file in $tmp_dir/ascii_images/*.txt; do
    #convert -size 1600x1200 xc:white -font 'UbuntuMono-Nerd-Font-Bold' -pointsize 12 -gravity center -annotate +0+0 "$(cat $file)" $tmp_dir/output_images/"$(basename "$file" .txt)".jpg
    convert -size "${new_width}x${new_height}" xc:white -font 'UbuntuMono-Nerd-Font-Bold' -pointsize 12 -gravity center -annotate +0+0 "$(cat $file)" $tmp_dir/output_images/"$(basename "$file" .txt)".jpg

    #jp2a "$file" --output=output_images/"$(basename "$file" .txt)".jpg
done

# Step4: Create Video output from Images
#cd output_images

#ffmpeg -framerate 12 -i $tmp_dir/output_images/%04d.jpg $cwd/output_video.mp4
#ffmpeg -framerate $fps -pattern_type glob -i "$tmp_dir/output_images/*.jpg" -c:v libx264 -pix_fmt yuv420p $cwd/output_video.mp4
ffmpeg -framerate $fps -pattern_type glob -i "$tmp_dir/output_images/*.jpg" -i $tmp_dir/audio.aac -c:v libx264 -pix_fmt yuv420p -c:a aac -strict experimental $cwd/output_video.mp4



rm -rf $tmp_dir
