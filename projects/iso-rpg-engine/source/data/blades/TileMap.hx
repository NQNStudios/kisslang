package data.blades;

typedef TileArray<T> = Array<Array<Int>>;

class TileMap {
    private var floorCodes:TileArray<Int>;
    private var terrainCodes:TileArray<Int>;

    private var width = 0;
    private var height = 0;

    private function tileArray<T>(defaultValue:T) {
        return [for (x in 0...width) [for (y in 0...height) defaultValue]];
    }

    public function new(width, height) {
        this.width = width;
        this.height = height;

        floorCodes = tileArray(255);
        terrainCodes = tileArray(0);
    }
}