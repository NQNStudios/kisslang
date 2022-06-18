package data.blades;

typedef TileArray<T> = Array<Array<T>>;

typedef TownDetails = {
    wallSheet1:Int,
    wallSheet2:Int
};

enum MapType {
    Town(underground:Bool, details:TownDetails);
    Outdoors(underground:Bool);
}

class TileMap {
    // TODO might need encapsulation
    public var floorCodes:TileArray<Int>;
    public var floorHeights:TileArray<Int>;
    public var terrainCodes:TileArray<Int>;

    public var width = 0;
    public var height = 0;

    public var name = "";

    private function tileArray<T>(defaultValue:T) {
        return [for (x in 0...width) [for (y in 0...height) defaultValue]];
    }

    public function wallSheet(num:Int) {
        return switch (type) {
            case Town(det):
                if (num == 1)
                    det.wallSheet1;
                else
                    det.wallSheet2;
            case Outdoors(true):
                614;
            case Outdoors(false):
                616;
        };
    }

    public function new(width, height, name, type) {
        this.width = width;
        this.height = height;
        this.name = name;
        floorCodes = tileArray(255);
        terrainCodes = tileArray(0);
        floorHeights = tileArray(9);
        this.type = type;
    }

    public var type:MapType;
    public var script = "";

    public function setFloor(x, y, code) {
        floorCodes[x][y] = code;
    }
    
    public function setFloorHeight(x, y, height) {
        floorHeights[x][y] = height;
    }
    
    public function setTerrain(x, y, code) {
        terrainCodes[x][y] = code;
    }
}