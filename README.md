#Shareit
A bash script to "optimize" files and upload them to your/a server via scp.

##What does it do?
 * It uploads files to your server.
 * Then it copies the public URL into your clipboard.
 * There is a .desktop file included so that you can add a context menu entry to share files within Dolphin file manager (KDE). Adapt the path to your shareit.sh script in that desktop file and place it in ~/.local/share/kservices5/ServiceMenus/. See https://wiki.natenom.com/w/Linux/KDE/Service_Menu for details.

##In some cases it does some extra work
###If file is a png or jpeg
 * Resize it to max 1920x1080 or any other configured value; can be disabled via config or via command line option.
 * Remove all metadata; can be disabled via config or via command line option.
 * Optimize the file; can be disabled via config or via command line option.
###If file is CR2 or ARW raw image
 * Extract the thumbnail image (mostly jpg) from the raw image and use that to upload; then proceed as above (for a jpeg file).
 * Automatically rotate the resulting jpeg file if needed to preserve the rotation.

##Example
> INFO: Image resized.
> INFO: Metadata removed.
> INFO: Image optimized.
> tmpfile.p6qLay                                                                                                                                              100%  351KB 351.3KB/s   00:00    
> INFO: Local URL: "/home/data/images/filebla.JPG"
> INFO: Remote URL: https://yourdomain.tld/sharing/caa76a06bcd2f26fea8a44af4afd6b4d223fe5321e31bn083dd7ecb33f995766.JPG
> Press Enter to quit...

##Dependencies
A lot...
 * Bash and probably many other shells.
 * scp
 * imagemagic (Resize images.)
 * optipng (image_optimize png files.)
 * jpegoptim (to image_optimize jpeg files.)
 * exiv2 (Metadata handling.)
 * dcraw (For Canon CR2 and Sony ARW raw images, and probably all other raw images someday.)
 * jhead (Rotate jpeg images.)
 * xsel (Copy the URL into your clipboard.)

##TODO
 * If several files were given then automatically create a zip file...
 * Ability to set a livetime for a file; not server based. When uploading a new file, check all files on the server??? and then remove them???

##Bugs
 * ...
