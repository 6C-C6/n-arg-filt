# n-arg-filt
锟斤拷锟斤拷

## This is a program that could reverse the disortion effect info in [filtered]

__It may takes a whole day to run, be patient__  
To start with gather all the frames, you may use ffmpeg to extract the frames.  
Run `ffmpeg -i "./filtered.mp4" "./filtered/f%04d.png"`, it will have 2565 frames with a total size of about 1.5GB.  

If you're in the initial run, enable init--init part; change the code to start with certain image, if you know what you're doing!  

To resume from a certain run, disabe init--init part,keep run_index, let shifts=prev_shifts and tar_img=prev_tar_img, then start the program.  

To finish the rest, let detRest=true, enable init--init and start.  

For each line in one frame, __shifts__ has 2 values, it represents the shift pixels from the original image to this line, 
like `img[n,line]=shift(tar_img[line],shifts[line][first][n])+shift(tar_img[line],shifts[line][second][n])`.  
Without futher analysis, this 2 values can't be distingushed from each other, i.e. change first to second doesn't matter.  

More things tbd...  