module code.fastappender3;

import core.memory;
import core.stdc.string;

/// Slice storer
struct FastAppender3(T, bool X)
{
	static assert(T.sizeof == 1, "TODO");

private:
	enum PAGE_SIZE = 4096;

	enum INDEX_NODE_SIZE = (PAGE_SIZE*64 / size_t.sizeof) - 2;

	alias const(T)[] Item;

	struct IndexNode
	{
		Item[INDEX_NODE_SIZE] items;
		Item* end;
		IndexNode* next;

		@property Item[] liveItems()
		{
			return items[0..end - items.ptr];
		}
	}
	IndexNode* head, tail;

	Item* indexCursor, indexEnd;

	void extendIndex()
	{
		//auto newNode = new IndexNode;
		auto newNode = cast(IndexNode*)GC.malloc(IndexNode.sizeof, 0);
		newNode.next = null;

		if (!tail)
			head = tail = newNode;
		else
		{
			tail.end = indexCursor;
			tail.next = newNode;
			tail = newNode;
		}

		indexCursor = newNode.items.ptr;
		indexEnd = indexCursor + INDEX_NODE_SIZE;
	}

	void consolidate()
	{
	    if (tail)
	    	tail.end = indexCursor;

		size_t length = 0;
		for (auto n = head; n; n = n.next)
			foreach (item; n.liveItems)
				length += item.length;

		auto s = new T[length];
		auto p = s.ptr;

		for (auto n = head; n; n = n.next)
			foreach (item; n.liveItems)
			{
				p[0..item.length] = item;
				p += item.length;
			}

		head = tail = null;
		extendIndex();
		*indexCursor++ = s;
	}

public:
	void put(U...)(U items)
	{
		static assert(items.length < INDEX_NODE_SIZE, "Too many items!");

		auto indexCursorL = indexCursor; // local copy
		auto indexPostCursor = indexCursorL + items.length;
		if (indexPostCursor > indexEnd)
		{
			extendIndex();
			indexCursorL = indexCursor;
			indexPostCursor = indexCursorL + items.length;
		}
		indexCursor = indexPostCursor;

		foreach (item; items)
			static if (is(typeof(item[0]) == immutable(T)))
			    *indexCursorL++ = item;
			else
				static assert(0, "Can't put " ~ typeof(item).stringof);
	}

	Item get()
	{
		consolidate();
		return head.items[0];
	}

/+
	// TODO: chaining?
	private T* cursor, start, end;

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
			auto extended = GC.extend(start, newSize, newSize * 2);
			if (extended)
			{
				end = start + extended;
				return;
			}
		}

		auto newCapacity = nextCapacity(newSize);
		//auto newStart = (new T[newCapacity]).ptr;

		auto bi = GC.qalloc(newCapacity * T.sizeof, (typeid(T[]).next.flags & 1) ? 0 : GC.BlkAttr.NO_SCAN);
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
+/
}

alias FastAppender3!(char, false) StringBuilder3;
alias FastAppender3!(char, true ) StringBuilder3X;

unittest
{
	StringBuilder3 sb;
	sb.put("Hello", " ", "world!");
	assert(sb.get() == "Hello world!");
}

unittest
{
	StringBuilder3X sb;
	sb.put("Hello", " ", "world!");
	assert(sb.get() == "Hello world!");
}
