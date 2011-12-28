import std.stdio;
import ae.sys.benchmark;

import common;

version(DOS)
	enum N = 100;
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
		bench!"StringBuilder4Multi";
	}
}
