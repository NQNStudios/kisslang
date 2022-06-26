
package zpartanlite;
import zpartanlite.Enumerables;

class Pages<T>
{
    
    
    private var index:      Int ;
    private var lastIndex:  Int ;
    private var len:        Int ;
    private var order:      Array<T> ;
    private var history:    Array<Int> ;
    public var circle:      Bool ;
    public var last:        T ;
    public var curr:        T ;
    public var pageChange:  DispatchTo ;
    public var hideNext:    DispatchTo ;
    public var hidePrev:    DispatchTo ;
    public var dir:         Travel;
    public var looped:      DispatchTo ;
    
    public function new( ?arr_: Array<T>, ?circle_: Bool = false )
    {
        
        circle      = circle_ ;
        pageChange  = new DispatchTo() ;
        hideNext    = new DispatchTo() ;
        hidePrev    = new DispatchTo() ;
        looped      = new DispatchTo() ;
        reset( arr_ ) ;
        
    }
    
    
    public function reset( ?arr_: Array<T> ) : Void
    {
        
        if( arr_ == null )
        {
            order   = new Array() ;
        }
        else
        {   
            order  = arr_ ;   
        }
        index = 0;
        len = order.length;
        history = new Array() ;
        
    }
    
    
    public function next() : T
    {
        
        lastIndex   = index ;
        last        = order[ index ];
        dir = Forward;
        
        index++ ;
        if( index == len )
        {
            if( circle )
            {
                index = 0 ;
                looped.dispatch();
            }
            else
            {
                index = len - 1 ;
            }
        }
        
        curr = order[ index ] ;
        if( lastIndex != index )
        {
            
            history.push( index ) ;
            
            if( !circle )
            {
                
                if( !hasNext() )
                {
                    
                    hideNext.dispatch();
                    
                }
                
            }
            pageChange.dispatch();
            
        }
        
        return curr;
        
    }
    
    
    public function previous(): T
    {
        
        lastIndex   = index ;
        last = order[ index ];
        dir = Back;
        
        index-- ;
        if( index == -1 )
        {
            
            if( circle )
            {
                
                index = len - 1 ;
                
            }
            else
            {
                
                index = 0 ;
            }
            
        }
        
        curr = order[ index ]; 
        if( lastIndex != index )
        {
            
            history.push( index ) ;
            
            if( !circle )
            {
                
                if( !hasPrevious() )
                {
                    
                    hidePrev.dispatch();
                    
                }
                
            }
            pageChange.dispatch();
        }
        
        
        return curr;
        
    }
    
    
    public function getCurrent(): T
    {
        
        return order[ index ] ;
        
    }
    
    
    public function hasPrevious(): Bool
    {
        
        if( circle )
        {
            
            return true ;
            
        }
        
        if( index == 0 )
        {
            
            return false ;
            
        }
        
        return true ;
        
    }
    
    
    public function hasNext() : Bool
    {
        
        if( circle )
        {
            
            return true ;
            
        }
        
        if( index == len )
        {
            
            return false ;
            
        }
        
        return true ;
        
    }
    
    
    public function goto( index_: Int ): T
    {
        
        lastIndex   = index ;
        last        = order[ index ] ;
        
        
        index = index_ ;
        
        curr = order[ index ];
        if( lastIndex != index )
        {
            
            history.push( index ) ;
            
            if( !circle )
            {
                
                if( !hasNext() )
                {
                    
                    hideNext.dispatch();
                    
                }
                if( !hasPrevious() )
                {
                    
                    hidePrev.dispatch();
                    
                }
            }
            
            pageChange.dispatch();
            
        }
        
        
        return curr;
        
    }
    
    
    public function back(): T
    {
        
        lastIndex = index ;
        last = order[ index ] ;
        
        index = history.pop() ;
        
        if( lastIndex != index )
        {
            if( !circle )
            {
                
                if( !hasNext() )
                {
                    
                    hideNext.dispatch() ;
                    
                }
                if( !hasPrevious() )
                {
                    
                    hidePrev.dispatch() ;
                    
                }
                
            }
            pageChange.dispatch() ;
            
        }
        
        curr = order[ index ] ;
        return curr;
        
    }
    
    public function isLast():Bool
    {
        
        if( index == len - 1 ) return true;
        return false;
        
    }
    
    public function getIndex(): Int
    {
        
        return index ;
        
    }
    
    public function getLastIndex(): Int
    {
        
        return lastIndex;
        
    }
    
    
}
