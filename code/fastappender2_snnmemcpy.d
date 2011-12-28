module code.fastappender2;

import core.memory;
import core.stdc.string;

import code.memcpy;

debug import std.stdio;

/// Optimized copying appender, no chaining
struct FastAppender2(T, bool X)
{
	static assert(T.sizeof == 1, "TODO");

	private enum MIN_SIZE  = 4096;
	private enum PAGE_SIZE = 4096;

	private T* cursor, start, end;

	// TODO: try array
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
					static if (X)
						memcpy(cursor, item.ptr, item.length);
					else
						cursor[0..item.length] = item;
					cursor += item.length;
				}
		}
	}

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

		auto newCapacity = nextCapacity(newSize);
		//auto newStart = (new T[newCapacity]).ptr;

		debug writeln("qalloc ", newCapacity);
		auto bi = GC.qalloc(newCapacity * T.sizeof, (typeid(T[]).next.flags & 1) ? 0 : GC.BlkAttr.NO_SCAN);
		debug writeln("  ==> ", bi.size);
		auto newStart = cast(T*)bi.base;
		newCapacity = bi.size;

		newStart[0..size] = start[0..size]; // TODO: memcpy?
		start = newStart;
		cursor = start + size;
		end = start + newCapacity;
	}

	// Round up to the next power of two, but after PAGE_SIZE only add PAGE_SIZE.
	private static size_t nextCapacity(size_t size)
	{
		if (size < MIN_SIZE)
			return MIN_SIZE;

		size--;
		auto sub = size;
		sub |= sub >>  1;
		sub |= sub >>  2;
		sub |= sub >>  4;
		sub |= sub >>  8;
		sub |= sub >> 16;
		static if (size_t.sizeof > 4)
			sub |= sub >> 32;

		return (size | (sub & (PAGE_SIZE-1))) + 1;
	}

	unittest
	{
		assert(nextCapacity(  PAGE_SIZE-1) ==   PAGE_SIZE);
		assert(nextCapacity(  PAGE_SIZE  ) ==   PAGE_SIZE);
		assert(nextCapacity(  PAGE_SIZE+1) == 2*PAGE_SIZE);
		assert(nextCapacity(2*PAGE_SIZE  ) == 2*PAGE_SIZE);
		assert(nextCapacity(2*PAGE_SIZE+1) == 3*PAGE_SIZE);
	}

	T[] get()
	{
		return start[0..cursor-start];
	}
}

alias FastAppender2!(char, false) StringBuilder2;
alias FastAppender2!(char, true ) StringBuilder2X;

unittest
{
	StringBuilder2 sb;
	sb.put("Hello", ' ', "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	StringBuilder2X sb;
	sb.put("Hello", ' ', "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	StringBuilder2 sb;
	foreach (n; 0..4096)
		sb.put("Hello", ' ', "world!");
	string s;
	foreach (n; 0..4096)
		s ~= "Hello world!";
	assert(sb.get() == s);
}

