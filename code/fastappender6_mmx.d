module code.fastappender6;

import core.memory;
import core.stdc.string;
import core.stdc.stdio;

debug import std.stdio;
debug import ae.utils.text;

__gshared const(char)[20] _d = "Yo this is aoeu\n\n\n";

/// Optimized align-copying appender with chaining.
/// Stores data together with linked-list node, which isn't GC-friendly.
struct FastAppender6(T, bool X)
{
	static assert(T.sizeof == 1, "TODO");

private:
	enum PAGE_SIZE = 4096;

	struct Node
	{
		Node* next;
		size_t size;
		size_t[2] dummy;
		// Problem: this will get GC-scanned
		T[0] data;

		// http://d.puremagic.com/issues/show_bug.cgi?id=7175
		@property T* dataPtr() { return cast(T*)(cast(ubyte*)&this + data.offsetof); }
	}

	enum MIN_SIZE  = PAGE_SIZE / 2;

	T* cursor, end; // start is tail.data.ptr
	Node* head, tail;
	size_t totalLength;

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

	enum size_t ALIGN_BITS = 4;  // TODO
	enum size_t ALIGN_SIZE = 1 << ALIGN_BITS;
	//enum size_t ALIGN_SIZE = size_t.sizeof;
	enum size_t ALIGN_MASK = ALIGN_SIZE - 1;
	enum size_t ALIGN_OVERHEAD = (2 * ALIGN_SIZE) - 1;
	enum size_t ALIGN_HEADER = 4 * size_t.sizeof;

	void consolidate()
	{
		if (head is null)
			return;

		tail.size = cursor - tail.dataPtr;
		tail.next = null;

		auto oldHead = head;
		head = tail = null;
		reserve(totalLength + size_t.sizeof*2);

		auto p = cursor;

		*cast(size_t*)p = totalLength;
		p += size_t.sizeof;
		*cast(size_t*)p = 0;
		p += size_t.sizeof;

		for (auto n = oldHead; n; n = n.next)
		{
			auto ptr = n.dataPtr;
			auto end = ptr + n.size;
			debug writeln(cast(void*)ptr, " .. ", cast(void*)end);
			debug writeln(hexDump(ptr[0..n.size]));
			while (ptr < end)
			{
				auto sz = (cast(size_t*)ptr)[0];
				debug writeln("sz=", sz);
				auto al = (cast(size_t*)ptr)[1];
				ptr += ALIGN_HEADER;
				auto ptra = ptr + al;
				p[0..sz] = ptra[0..sz];
				p += sz;
				ptr += (sz+ALIGN_OVERHEAD) & ~ALIGN_MASK;
			}
		}
		cursor = p;
	}

	debug static void writeInt(size_t i)
	{
		writefln("%X", i);
	}

	debug static void writeChar(char c)
	{
		writeln(c);
	}

	// TODO: combine padding size with length?
	static T* addItem(const(T)[] item, T* cursor)
	{
		version (D_InlineAsm_X86)
		{
			asm
			{
				naked;
				// EAX, ECX, EDX are scratch registers and can be destroyed by a function.
				// EBX, ESI, EDI, EBP must be preserved across function calls.

			//	pushad; mov AL, 0x3C; call writeChar; popad;

				push ESI;
				push EDI;

			//	pushad; call writeInt; popad;

				mov ECX, dword ptr [12+ESP+0]; // length
			//	pushad; mov EAX, ECX; call writeInt; popad;
				mov dword ptr [EAX  ], ECX;
				mov ESI, dword ptr [12+ESP+4]; // ptr
				mov EDX, ESI;
				and EDX, ALIGN_MASK;
				mov dword ptr [EAX+4], EDX;
				add EAX, ALIGN_HEADER;
				and ESI, ~ALIGN_MASK;
				mov EDI, EAX;
			//	pushad; mov EAX, ECX; call writeInt; popad;
			//	pushad; mov EAX, ESI; call writeInt; popad;
			//	pushad; mov EAX, EDI; call writeInt; popad;
				add ECX, ALIGN_OVERHEAD; // 2*ALIGN_SIZE - 2
				and ECX, ~ALIGN_MASK; // !!
/*
			//	pushad; mov EAX, ECX; call writeInt; popad;
				shr ECX, 2;
				rep; movsd;
			//	add EDI, ECX;
				mov EAX, EDI;
*/
			//	shr ECX, 4;

				mov EAX, EDI;
				add EAX, ECX;

			loop:
			//	dec ECX;
				sub ECX, 16;
				pushad; mov EAX, ECX;               call writeInt; popad;
				pushad; mov EAX, ECX; add EAX, ESI; call writeInt; popad;
				pushad; mov EAX, ECX; add EAX, EDI; call writeInt; popad;
				movaps XMM0, [ESI+ECX];
				movaps [EDI+ECX], XMM0;
				test ECX, ECX;
				jz loop;


			//	pushad; call writeInt; popad;
			//	pushad; mov AL, 0x3E; call writeChar; popad;

				pop EDI;
				pop ESI;
				ret 8;
			}
		}
		else
		{
			debug writeln(item.length);
			
			auto start = cast(T*)item.ptr;
			auto len = item.length;

			*cast(size_t*)cursor = len;
			cursor += size_t.sizeof;
			*cast(size_t*)cursor = cast(size_t)start & ALIGN_MASK;
			cursor += size_t.sizeof;

			auto end = start + len;
			start = cast(T*)(cast(size_t)start & ~ALIGN_MASK);
			end   = cast(T*)((cast(size_t)end + ALIGN_MASK) & ~ALIGN_MASK);
			len   = end - start;

			cursor[0..len] = start[0..len];
			cursor += len;
			return cursor;
		}
	}

public:
	void put(U...)(U items)
	{
	//	debug writeln("<<");
		size_t len;
		foreach (item; items)
			static if (is(typeof(cursor[0] = item)))
				len++;
			else
			// TODO: is this too lax? it allows passing static arrays by value
			static if (is(typeof(cursor[0..1] = item[0..1])))
				len += item.length;
			else
				static assert(0, "Can't put " ~ typeof(item).stringof);

		// TODO: check for static if length is 1
		auto cursorEndEstimate = cursor + len + (items.length * (2 * size_t.sizeof + ALIGN_OVERHEAD));
		this.totalLength += len;

		if (cursorEndEstimate > end)
		{
			auto lengthEstimate = cursorEndEstimate - cursor;
			reserve(lengthEstimate);
		}
		auto p = this.cursor;

		foreach (i, item; items)
			static if (is(typeof(cursor[0..1] = item[0..1])))
				p = addItem(items[i], p);

		assert(p >= cursor && p <= end);

		this.cursor = p;
	//	debug writeln(">>");
	}

	T[] get()
	{
		debug writeln("!!");
		if (tail)
		{
			consolidate();
			auto ptr = tail.dataPtr + size_t.sizeof*2;
			return ptr[0 .. cursor - ptr];
		}
		else
			return null;
	}
}

alias FastAppender6!(char, false) StringBuilder6;
alias FastAppender6!(char, true ) StringBuilder6X;

unittest
{
	StringBuilder6 sb;
	sb.put("Hello", " ", "world!");
	import ae.utils.text;
	import std.stdio;
	writeln("RESULT:\n", hexDump(cast(ubyte[])sb.get()));
}

unittest
{
	StringBuilder6 sb;
	sb.put("Hello", " ", "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	StringBuilder6X sb;
	sb.put("Hello", " ", "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	StringBuilder6 sb;
	foreach (n; 0..4096)
		sb.put("Hello", " ", "world!");
	string s;
	foreach (n; 0..4096)
		s ~= "Hello world!";
	assert(sb.get() == s);
}
