package kiss_spaced_rep;

typedef Continuation = Void -> Void;

typedef StudyEngine = {
    clear: Void -> Void,
    print: (String) -> Void,
    println: (String) -> Void,
    showImage: (String) -> Void,
    printCC: (String, Continuation) -> Void,
    printlnCC: (String, Continuation) -> Void,
    showImageCC: (String, Continuation) -> Void,
    input: (String->Void) -> Void
};
