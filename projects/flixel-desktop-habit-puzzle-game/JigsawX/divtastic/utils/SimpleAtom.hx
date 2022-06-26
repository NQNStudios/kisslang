
package divtastic.rss;
import js.Lib;
import haxe.Http;
import haxe.xml.Fast;

typedef Feed = 
{

    var id:                String;
    var title:             String;
    var updated:           Date;
    var link_atom:         String;
    var link_html:         String;
    var subtitle:          String;

}

typedef Entry = 
{
    
    var id:               String;
    var title:            String;
    var published:        Date;
    var updated:          Date;
    var author_name:      String;
    var content:          String;
    var link_html:        String;
    
}

typedef Topic =
{
    var topic:                  String;
    var entries:                Array<Entry>;
}

class SimpleAtom
{
    
    public var feedInfo:        Feed;
    public var entries:         Array<Entry>;
    public var topics:          Array<Topic>;
    private var file:           String;
    private var atomXML:        Fast;
    
    
    public function new()
    {
    
    }
    
    public function load( file )
    {
        
        var r       = new Http( file );
        r.onError   = Lib.alert;
        r.onData    = atomLoaded;
        r.request( false );
        
    }
    
    
    public function atomLoaded( r ) 
    {
        
        atomXML = new Fast( Xml.parse( r ).firstElement() );
        createFeedInfo();
        createEntries();
    }
    
    
    private function createFeedInfo( )
    {
        feedInfo =  {   id:        atomXML.node.id.innerData
                    ,   title:     atomXML.node.title.innerData
                    ,   updated:   createDate( atomXML.node.updated.innerData )
                    ,   link_atom: atomXML.nodes.link.first().att.href
                    ,   link_html: atomXML.nodes.link.last().att.href
                    ,   subtitle:  atomXML.node.subtitle.innerData
                    }
        
    }
    
    
    // TODO: content here may need to be decoded to html
    // TODO: Split up sorting as not all Atoms need topic sorting
    // TODO: Add dispatchTo signal for when finished loading... and or parsing
    public function createEntries()
    {
        
        var content: String;
        entries = new Array();
        var aEntries: Entry;
        
        for( anEntry in atomXML.nodes.entry )
        {
            if( anEntry.hasNode.content )
            {
                
                content = anEntry.node.content.innerData;
                
            }
            else
            {
                
                content = anEntry.node.summary.innerData;
                
            }
            var content = 
            aEntries      = { id:                 anEntry.node.id.innerData
                            , title:              anEntry.node.title.innerData
                            , published:          createDate( anEntry.node.published.innerData )
                            , updated:            createDate( anEntry.node.updated.innerData )
                            , author_name:        anEntry.node.author.node.name.innerData
                            , content:            content
                            , link_html:          anEntry.node.link.att.href
                            }
            
            entries.push( aEntries );
            
        }
    
        entries.sort( byTopic );
        
        topics = new Array();
        var topic: Topic = null;
        var currTopic = '';
        var newTopic: String;
        var topicEntries: Array<Entry>= new Array();
        
        for( i in 0...entries.length )
        {
            
            aEntries = entries[ i ];
            newTopic = aEntries.title;
            
            if( newTopic != currTopic )
            {
                if( topicEntries.length != 0 ) 
                {
                    topicEntries.sort( byDate );
                    topic = { topic: aEntries.title, entries: topicEntries };
                    topics.push( topic );
                }
                
                topicEntries = new Array();
                
            }
            
            topicEntries.push( aEntries );
            
        }
        topics.push( topic );
        //trace(entries.last());
        trace(topics[0]);
    }
    
    
    private function byDate( a: Entry, b: Entry ): Int
    {
        
        return Reflect.compare( a.published, b.published );
        
    }
    
    
    private function byTopic( a: Entry, b: Entry ): Int
    {
        
        return Reflect.compare( a.title.toLowerCase(), b.title.toLowerCase() );
        
    }
    
    
    private function createDate( dateS: String ): Date
    {
        
        if( dateS.split('T').length != 2 || dateS.substr(dateS.length-1,1) != 'Z' )
        {
            
            trace( 'date format has failed please modify code!!') ;
            return Date.now();
            
        }
        
        return new Date (   /* var year  =  */ Std.parseInt( dateS.substr(  0, 4 ) )
                        ,   /* var month =  */ Std.parseInt( dateS.substr(  6, 2 ) )
                        ,   /* var day   =  */ Std.parseInt( dateS.substr(  8, 2 ) )
                        ,   /* var hour  =  */ Std.parseInt( dateS.substr( 10, 2 ) )
                        ,   /* var min   =  */ Std.parseInt( dateS.substr( 12, 2 ) )
                        ,   /* var sec   =  */ Std.parseInt( dateS.substr( 14, 2 ) )
                        );
    }
    
}


/** Notes on Atom Dates **
for this code and simplicity assumes date in nabble are as per the haxe mailing list atom: 
'YYYY-MM-DD' + 'T' + 'HH:MM:SS' + 'Z'

but notes below for future reference

     Standard for ARPA Internet Text Messages
     
     
     
5. DATE AND TIME SPECIFICATION

     
     
5.1. SYNTAX

     
     date-time   =  [ day "," ] date time        ; dd mm yy
                                                 ;  hh:mm:ss zzz
     
     day         =  "Mon"  / "Tue" /  "Wed"  / "Thu"
                 /  "Fri"  / "Sat" /  "Sun"
     
     date        =  1*2DIGIT month 2DIGIT        ; day month year
                                                 ;  e.g. 20 Jun 82
     
     month       =  "Jan"  /  "Feb" /  "Mar"  /  "Apr"
                 /  "May"  /  "Jun" /  "Jul"  /  "Aug"
                 /  "Sep"  /  "Oct" /  "Nov"  /  "Dec"
     
     time        =  hour zone                    ; ANSI and Military
     
     hour        =  2DIGIT ":" 2DIGIT [":" 2DIGIT]
                                                 ; 00:00:00 - 23:59:59
     
     zone        =  "UT"  / "GMT"                ; Universal Time
                                                 ; North American : UT
                 /  "EST" / "EDT"                ;  Eastern:  - 5/ - 4
                 /  "CST" / "CDT"                ;  Central:  - 6/ - 5
                 /  "MST" / "MDT"                ;  Mountain: - 7/ - 6
                 /  "PST" / "PDT"                ;  Pacific:  - 8/ - 7
                 /  1ALPHA                       ; Military: Z = UT;
                                                 ;  A:-1; (J not used)
                                                 ;  M:-12; N:+1; Y:+12
                 / ( ("+" / "-") 4DIGIT )        ; Local differential
                                                 ;  hours+min. (HHMM)
     
     
5.2. SEMANTICS

     
          If included, day-of-week must be the day implied by the date
     specification.
     
          Time zone may be indicated in several ways.  "UT" is Univer-
     sal  Time  (formerly called "Greenwich Mean Time"); "GMT" is per-
     mitted as a reference to Universal Time.  The  military  standard
     uses  a  single  character for each zone.  "Z" is Universal Time.
     "A" indicates one hour earlier, and "M" indicates 12  hours  ear-
     lier;  "N"  is  one  hour  later, and "Y" is 12 hours later.  The
     letter "J" is not used.  The other remaining two forms are  taken
     from ANSI standard X3.51-1975.  One allows explicit indication of
     the amount of offset from UT; the other uses  common  3-character
     strings for indicating time zones in North America.
     
     
     August 13, 1982              - 26 -                      RFC #822
*/
