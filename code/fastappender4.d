module code.fastappender4;

import core.memory;
import core.stdc.string;

debug import std.stdio;

/// Optimized copying appender with chaining.
/// Stores data together with linked-list node, which isn't GC-friendly.
struct FastAppender4(T, bool X)
{
	static assert(T.sizeof == 1, "TODO");

private:
	enum PAGE_SIZE = 4096;

	struct Node
	{
		Node* next;
		size_t size;
		// Problem: this will get GC-scanned
		T[0] data;

		// http://d.puremagic.com/issues/show_bug.cgi?id=7175
		@property T* dataPtr() { return cast(T*)(cast(ubyte*)&this + data.offsetof); }
	}

	enum MIN_SIZE  = PAGE_SIZE / 2;

	T* cursor, end; // start is tail.data.ptr
	Node* head, tail;

	void reserve(size_t minSize)
	{
		if (tail)
		{
			auto size = Node.sizeof + (end - tail.dataPtr);
			if (size >= PAGE_SIZE)
			{
				auto newSize = size + minSize;

				auto block = cast(T*)tail;
				debug writeln("extend ", newSize, " .. ", newSize * 2);
				auto extended = GC.extend(block, newSize, newSize * 2);
				debug writeln("  --> ", extended);
				if (extended)
				{
					end = block + extended;
					return;
				}
			}
		}

		auto newCapacity = minSize + Node.sizeof + (tail ? (end - tail.dataPtr) * 8 : MIN_SIZE);
		debug writeln("qalloc ", newCapacity);
		auto bi = GC.qalloc(newCapacity, 0);
		debug writeln("  ==> ", bi.size);
		auto node = cast(Node*)bi.base;

		if (tail)
		{
			tail.size = cursor - tail.dataPtr;
			tail.next = node;
			tail = node;
		}
		else
			head = tail = node;

		cursor = node.dataPtr;
		end = cast(T*) (cast(ubyte*)bi.base + bi.size);
	}

	void consolidate()
	{
		if (head is tail) // also if null
			return;

		tail.size = cursor - tail.dataPtr;
		tail.next = null;

		size_t length;
		for (auto n = head; n; n = n.next)
			length += n.size;

		auto oldHead = head;
		head = tail = null;
		reserve(length);

		auto p = cursor;
		for (auto n = oldHead; n; n = n.next)
		{
			p[0..n.size] = n.dataPtr[0..n.size];
			p += n.size;
		}
		cursor = p;
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
					/+static if (X)
					{
						auto itemPtr = item.ptr;
						auto itemLen = item.length;
						asm
						{
							mov ESI, itemPtr;
							mov EDI, cursor;
							mov ECX, itemLen;

							rep;
							movsb;
                            /*
							add ECX, 3;
							shr ECX, 2;
							rep;
							movsd;
                            */
						}
					}
					else+/
						cursor[0..item.length] = item;
					cursor += item.length;
				}
		}
	}

	T[] get()
	{
		if (tail)
		{
			consolidate();
			return tail.dataPtr[0..cursor - tail.dataPtr];
		}
		else
			return null;
	}
}

alias FastAppender4!(char, false) StringBuilder4;
alias FastAppender4!(char, true ) StringBuilder4X;

unittest
{
	debug writeln("======================");
	StringBuilder4 sb;
	sb.put("Hello", ' ', "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	debug writeln("======================");
	StringBuilder4X sb;
	sb.put("Hello", ' ', "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	debug writeln("======================");
	StringBuilder4 sb;
	foreach (n; 0..4096)
		sb.put("Hello", ' ', "world!");
	string s;
	foreach (n; 0..4096)
		s ~= "Hello world!";
	assert(sb.get() == s);
}

