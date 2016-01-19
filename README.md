#Thumbnail-kit

thumbnail-kit genarates thumbnails as iOS image resources inclueds @3x, @2x and @1x.  

##Usage

Execute *bin/thumbnail-kit* to genarate thumbnails into **thumbnails** directory which is also created by thumbnail-kit.
This script requires one argument which is a path of image file.

```
$ ./bin/thumbnail-kit ~/sample.png
$ ls ~/thumbnails/
sample@1x.png sample@2x.png sample@3x.png
```



