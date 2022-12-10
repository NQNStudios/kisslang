package year2022;

typedef SizeStats = Map<String,Int>;

enum FileSystem {
    File(size:Int);
    Folder(contents:Map<String,FileSystem>);
}
