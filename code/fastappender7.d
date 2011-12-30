module code.fastappender7;

import core.memory;
import core.stdc.string;

debug import std.stdio;

/// Optimized non-copying chained expanding appender.
struct FastAppender7(T, bool X)
{
	static assert(T.sizeof == 1, "TODO");

private:
	enum MIN_SIZE  = 4096;
	enum PAGE_SIZE = 4096;

	T* cursor, start, end;

	struct Node
	{
		T* ptr;
		size_t size;
		Node* prev;
	}
	Node* history;

	void reserve(size_t len)
	{
		auto size = cursor-start;
		auto newSize = size + len;
		auto capacity = end-start;

		if (start)
		{
			debug writeln("extend ", newSize, " .. ", newSize * 2);
			auto extended = GC.extend(start, newSize, newSize * 2);
			debug writeln("  --> ", extended);
			if (extended)
			{
				end = start + extended;
				return;
			}
		}

		auto newCapacity = newSize < MIN_SIZE ? MIN_SIZE : newSize * 2;
		//auto newStart = (new T[newCapacity]).ptr;

		debug writeln("qalloc ", newCapacity);
		auto bi = GC.qalloc(newCapacity * T.sizeof, (typeid(T[]).next.flags & 1) ? 0 : GC.BlkAttr.NO_SCAN);
		debug writeln("  ==> ", bi.size);
		auto newStart = cast(T*)bi.base;
		newCapacity = bi.size;

		auto n = new Node;
		n.ptr = start;
		n.size = size;
		n.prev = history;
		history = n;

		//newStart[0..size] = start[0..size];
		start = newStart;
		cursor = start + size;
		end = start + newCapacity;
	}

	void coalesce()
	{
		while (history)
		{
			auto s0 = history.prev ? history.prev.size : 0;
			auto s1 = history.size;
			start[s0..s1] = history.ptr[s0..s1];
			history = history.prev;
		}
	}

public:
	void put(U...)(U items)
	{
		// TODO: check for static if length is 1
		auto cursorEnd = cursor;
		foreach (item; items)
			static if (is(typeof(cursor[0] = item)))
				cursorEnd++;
			else
			// TODO: is this too lax? it allows passing static arrays by value
			static if (is(typeof(cursor[0..1] = item[0..1])))
				cursorEnd += item.length;
			else
				static assert(0, "Can't put " ~ typeof(item).stringof);

		if (cursorEnd > end)
		{
			auto len = cursorEnd - cursor;
			reserve(len);
			cursorEnd = cursor + len;
		}
		auto cursor = this.cursor;
		this.cursor = cursorEnd;

		static if (items.length == 1)
		{
			alias items[0] item;
			static if (is(typeof(cursor[0] = item)))
				cursor[0] = item;
			else
				cursor[0..item.length] = item;
		}
		else
		{
			foreach (item; items)
				static if (is(typeof(cursor[0] = item)))
					*cursor++ = item;
				else
				static if (is(typeof(cursor[0..1] = item[0..1])))
				{
					cursor[0..item.length] = item;
					cursor += item.length;
				}
		}
	}

	T[] get()
	{
		coalesce();
		return start[0..cursor-start];
	}
}

alias FastAppender7!(char, false) StringBuilder7;
alias FastAppender7!(char, true ) StringBuilder7X;

unittest
{
	debug writeln("======================");
	StringBuilder7 sb;
	sb.put("Hello", " ", "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	debug writeln("======================");
	StringBuilder7X sb;
	sb.put("Hello", " ", "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	debug writeln("======================");
	StringBuilder7 sb;
	foreach (n; 0..4096)
		sb.put("Hello", " ", "world!");
	string s;
	foreach (n; 0..4096)
		s ~= "Hello world!";
	assert(sb.get() == s);
}

unittest
{
	debug writeln("======================");
	StringBuilder7X sb;
	foreach (n; 0..4096)
		sb.put("Hello", " ", "world!");
	string s;
	foreach (n; 0..4096)
		s ~= "Hello world!";
	assert(sb.get() == s);
}

