package jigsawx.ds;
enum Sign{
    UP;
    DOWN;
}
class CircleIter {
    var begin:              Float;
    var fin:                Float;
    var step:               Float;
    var min:                Float;
    var max:                Float;
    var current:            Float;
    var onDirection:        Sign;
    public static function pi2(     begin_:     Float
                                ,   fin_:       Float
                                ,   step_:      Float 
                                ){ 
        return new CircleIter( begin_, fin_, step_, 0, 2*Math.PI );
    }
    public static function pi2pi(   begin_:     Float
                                ,   fin_:       Float
                                ,   step_:      Float
                                ){
        return new CircleIter( begin_, fin_, step_, -Math.PI, Math.PI );
    }
    public function new (   begin_:     Float
                        ,   fin_:       Float
                        ,   step_:      Float
                        ,   min_:       Float
                        ,   max_:       Float 
                        ){
        begin           = begin_;
        current         = begin;
        fin             = fin_;
        step            = step_;
        min             = min_;
        max             = max_;
        onDirection     = ( step > 0 )? UP: DOWN;
    }
    public function reset(): CircleIter{
        current = begin;
        return this;
    }
    public function hasNext(): Bool {
        switch onDirection {
            case UP:
                return ( ( current < fin && current + step > fin ) || current == fin )? false: true;
            case DOWN:
                return ( ( current > fin && (( current - step ) < fin) )|| current == fin )? false: true;
        }
    }
    public function next() {
        current += step;
        switch onDirection{
            case UP:    if( current > max ) current = min + current - max;
            case DOWN:    if( current < min )    current = max + current - min;
        }
        if( !hasNext() ) return fin;
        return current;
    }
}
