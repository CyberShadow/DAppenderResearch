import std.stdio;
import ae.sys.benchmark;

import common;

version(DOS)
	enum N = 100;
else
debug
	enum N = 1;
else
	enum N = 10_000;

// **************************************************************************************

void bench(string name)()
{
	benchStart();
	foreach (i; 0..N)
	{
		mixin("test" ~ name ~ "();");
	}
	auto time = benchEnd();
	writefln("%12s - %s", time, name);
}

void main()
{
	foreach (n; 0..3)
	{
		writeln("* Pass ", n+1);
//		bench!"Append";
//		bench!"Appender";
//		bench!"Appender2Single";
		bench!"Appender2Multi";
//		bench!"AppenderConcat";
//		bench!"AppenderFastJoin";
//		bench!"FastAppenderSingle";
//		bench!"FastAppenderMulti";
//		bench!"AppendConcat";
//		bench!"AppendFastJoin";
//		bench!"AppendFastJoinArrInit";
//		bench!"AppendFastJoinArrAssign";
//		bench!"StringBuilder2Single";
//		bench!"StringBuilder2SingleX";
		bench!"StringBuilder2Multi";
//		bench!"StringBuilder2MultiX";
//		bench!"StringBuilder3Multi";
//		bench!"StringBuilder4Multi";
//		bench!"StringBuilder4MultiX";
//		bench!"StringBuilder5Multi";
		bench!"StringBuilder6Multi";
	}
}
