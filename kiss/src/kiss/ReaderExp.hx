package kiss;

import kiss.Stream;

typedef ReaderExp = {
    pos:Position,
    def:ReaderExpDef
};

enum ReaderExpDef {
    CallExp(func:ReaderExp, args:Array<ReaderExp>); // (f a1 a2...)
    ListExp(exps:Array<ReaderExp>); // [v1 v2 v3]
    StrExp(s:String); // "literal"
    Symbol(name:String); // s
    RawHaxe(code:String); // #| haxeCode() |# // deprecated!
    RawHaxeBlock(code:String); // #{ haxeCode(); moreHaxeCode(); }#
    TypedExp(path:String, exp:ReaderExp); // :Type [exp]
    MetaExp(meta:String, exp:ReaderExp); // &meta [exp]
    FieldExp(field:String, exp:ReaderExp); // .field [exp]
    KeyValueExp(key:ReaderExp, value:ReaderExp); // =>key value
    Quasiquote(exp:ReaderExp); // `[exp]
    Unquote(exp:ReaderExp); // ,[exp]
    UnquoteList(exp:ReaderExp); // ,@[exp]
    ListEatingExp(exps:Array<ReaderExp>); // [::exp exp ...exps exp]
    ListRestExp(name:String); // ...exps or ...
    None; // not an expression, i.e. (#unless falseCondition exp)
}
