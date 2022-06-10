package data.blades;

typedef TileArray<T> = Array<Array<T>>;

class TileMap {
    // TODO might need encapsulation
    public var floorCodes:TileArray<Int>;
    public var floorHeights:TileArray<Int>;
    private var terrainCodes:TileArray<Int>;

    private var width = 0;
    private var height = 0;

    public var name = "";

    private function tileArray<T>(defaultValue:T) {
        return [for (x in 0...width) [for (y in 0...height) defaultValue]];
    }

    public function new(width, height, name) {
        this.width = width;
        this.height = height;
        this.name = name;
        floorCodes = tileArray(255);
        terrainCodes = tileArray(0);
        floorHeights = tileArray(9);
    }

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