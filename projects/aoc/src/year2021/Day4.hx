package year2021;

import haxe.ds.Option;

typedef Board = {
    uncalled:Array<Array<Option<Int>>>,
    called:Array<Array<Option<Int>>>,
    won:Bool
};

typedef GameState = {
    numbersToCall:Array<Int>,
    boards:Array<Board>,
    boardsByNumber:Map<Int,Array<Board>>,
};
