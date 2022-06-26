
package utils;

enum UKweekDays
{    
    SUNDAY;
    MONDAY;
    TUESDAY;
    WEDNESDAY;
    THURSDAY;
    FRIDAY;
    SATURDAY;
}
enum UKmonths
{
    JANUARY;
    FEBRUARY;
    MARCH;
    APRIL;
    MAY;
    JUNE;	
    JULY;
    AUGUST;
    SEPTEMBER;
    OCTOBER;
    NOVEMBER;
    DECEMBER;
}

class CalendarMonthUtil
{
    
    public static inline var cols:  Int = 7;
    
    public var monthDays:           Int;
    public var dateInMonth:         Int;
    public var date:                Date;
    public var startOffset:         Int;
    
    public var rows:                Int;
    public var dayNo:               Int;
    public var currentMonth:        Int;
    public var monthBefore:         Int;
    public var monthAfter:          Int;
    public var currentMonthName:    String;
    public var monthBeforeName:     String;
    public var monthAfterName:      String;
    public var months:              Array<UKmonths>;
    public var weekDays:            Array<UKweekDays>;
    
    
	public function new( date_: Date )
	{
	    
		date = date_;
		
		months          = Type.allEnums( UKmonths );
		weekDays        = Type.allEnums( UKweekDays );
		
		update();
	    
	}
	
	public function monthOffset( no: Int )
	{
	    
	    date = new Date(    date.getFullYear()
                        ,   date.getMonth() + no
                        ,   date.getDay()
                        ,   date.getHours()
                        ,   date.getMinutes()
                        ,   date.getSeconds()
                        );
        update();
	    
	}
	
	public function next()
	{
	    date = new Date(    date.getFullYear()
                        ,   date.getMonth() + 1
                        ,   date.getDay()
                        ,   date.getHours()
                        ,   date.getMinutes()
                        ,   date.getSeconds()
                        );
        update();
	}
	
	public function previous()
	{
	    date = new Date(    date.getFullYear()
                        ,   date.getMonth()
                        ,   date.getDay()
                        ,   date.getHours()
                        ,   date.getMinutes()
                        ,   date.getSeconds()
                        );
        update();
	}
	
	public function update()
	{
	    
	    monthDays           = DateTools.getMonthDays( date );
	    dateInMonth         = date.getDate();
	    dayNo               = date.getDay();
	    var daysDifference  = dayNo;
        var defaultNameDay  = dateInMonth % cols;
        
	    if( defaultNameDay > dayNo )
	    {
	        daysDifference += cols;
	    }
	    
	    startOffset         = -( daysDifference - defaultNameDay - 1 );
        rows                = Math.ceil( (monthDays - startOffset + 1)/cols );
        
        currentMonth        = date.getMonth();
        monthBefore         = ( currentMonth == 0 )? 11: currentMonth - 1;
        monthAfter          = ( currentMonth == 11 )? 0: currentMonth + 1;  
        
        currentMonthName    = Std.string( months[ currentMonth ] );
        monthBeforeName     = Std.string( months[ monthBefore ] );
        monthAfterName      = Std.string( months[ monthAfter ] );
        
	}
    
}
