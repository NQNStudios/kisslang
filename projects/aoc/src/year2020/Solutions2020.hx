package year2020;

import haxe.ds.Map;
import haxe.Int64;
import StringTools;
import kiss.Prelude;
import kiss.Stream;
import year2020.SummingTuples;
import year2020.Passwords;
import year2020.Toboggan;
import year2020.Passports;
import year2020.Seating;
import year2020.Customs;
import year2020.Bags;
#if (day8 && year2020)
import year2020.BootCode;
#end
import year2020.Adapters;
#if (day11 && year2020)
import year2020.FerrySim;
#end
#if (day12 && year2020)
import year2020.Evasion;
#end

@:build(kiss.Kiss.build())
class Solutions2020 {}
