module common;

//import std.datetime;
//import std.string;
//import std.exception;
//import std.stdio;
import std.array;
import core.stdc.string;

import code.appender2;
import code.fastappender;
import code.fastappender2;
import code.fastappender3;
import code.fastappender4;
import code.fastappender5;
import code.fastappender6;

__gshared:

enum M = 1000;

string fastJoin(string[] strings...)
{
	size_t length = 0;
	foreach (s; strings)
		length += s.length;
	auto result = new char[length];
	auto p = result.ptr;
	foreach (s; strings)
	{
		memcpy(p, s.ptr, s.length);
		p += s.length;
	}
	return cast(string)result;
}

string fastJoinArr(string[] strings)
{
	size_t length = 0;
	foreach (s; strings)
		length += s.length;
	auto result = new char[length];
	auto p = result.ptr;
	foreach (s; strings)
	{
		memcpy(p, s.ptr, s.length);
		p += s.length;
	}
	return cast(string)result;
}

string s1 = "aeou";
string s2 = "iueiue";
string s3 = "459ota";
string s4 = "5849otues";
string s5 = "poucil";

// **************************************************************************************

extern(C):
export:

string testAppend()
{
	string result;
	foreach (m; 0..M)
	{
		result ~= `<table id="group-index" class="forum-table group-wrapper viewmode-`;
		result ~= s1;
		result ~= `">`;
		result ~= `<tr class="group-index-header"><th><div>`;
		result ~= s2;
		result ~= `</div></th></tr>`;
		result ~= s3;
		result ~= `<tr><td class="group-threads-cell"><div class="group-threads"><table>`;
		result ~= s4;
		result ~= `</table></div></td></tr>`;
		result ~= s5;
		result ~= `</table>`;
	}
	return result;
}

enum mixResultPutSingle = q{
	result.put(`<table id="group-index" class="forum-table group-wrapper viewmode-`);
	result.put(s1);
	result.put(`"><tr class="group-index-header"><th><div>`);
	result.put(s2);
	result.put(`</div></th></tr>`);
	result.put(s3);
	result.put(`<tr><td class="group-threads-cell"><div class="group-threads"><table>`);
	result.put(s4);
	result.put(`</table></div></td></tr>`);
	result.put(s5);
	result.put(`</table>`);
};

enum mixResultPutMulti = q{
	result.put(
		`APPENDER2 ="group-index" class="forum-table group-wrapper viewmode-`, s1, `">`
		`<tr class="group-index-header"><th><div>`, s2, `</div></th></tr>`, s3,
		`<tr><td class="group-threads-cell"><div class="group-threads"><table>`,
		s4, 
		`</table></div></td></tr>`,
		s5,
		`</table>`
	);
};

string testAppender()
{
	auto result = appender!string;
	foreach (m; 0..M)
	{
		mixin(mixResultPutSingle);
	}
	return result.data;
}

string testAppender2Single()
{
	Appender2!string result;
	foreach (m; 0..M)
	{
		mixin(mixResultPutSingle);
	}
	return result.data;
}

string testAppender2Multi()
{
	Appender2!string result;
	foreach (m; 0..M)
	{
		mixin(mixResultPutMulti);
	}
	return result.data;
}

string testAppenderConcat()
{
	auto result = appender!string;
	foreach (m; 0..M)
	{
		result.put(
			`<table id="group-index" class="forum-table group-wrapper viewmode-` ~ s1 ~ `">` ~
			`<tr class="group-index-header"><th><div>` ~ s2 ~ `</div></th></tr>` ~ s3 ~
			`<tr><td class="group-threads-cell"><div class="group-threads"><table>` ~
			s4 ~ 
			`</table></div></td></tr>` ~
			s5 ~
			`</table>`
		);
	}
	return result.data;
}

string testAppenderFastJoin()
{
	auto result = appender!string;
	foreach (m; 0..M)
	{
		result.put(fastJoin(
			`FASTJOIN ="group-index" class="forum-table group-wrapper viewmode-`, s1, `">`
			`<tr class="group-index-header"><th><div>`, s2, `</div></th></tr>`, s3,
			`<tr><td class="group-threads-cell"><div class="group-threads"><table>`,
			s4, 
			`</table></div></td></tr>`,
			s5,
			`</table>`,
		));
	}
	return result.data;
}


string testFastAppenderSingle()
{
	FastAppender!string result;
	foreach (m; 0..M)
	{
		mixin(mixResultPutSingle);
	}
	return result.data;
}

string testFastAppenderMulti()
{
	FastAppender!string result;
	foreach (m; 0..M)
	{
		mixin(mixResultPutMulti);
	}
	return result.data;
}

string testAppendConcat()
{
	string result;
	foreach (m; 0..M)
	{
		result ~=
			`<table id="group-index" class="forum-table group-wrapper viewmode-` ~ s1 ~ `">` ~
			`<tr class="group-index-header"><th><div>` ~ s2 ~ `</div></th></tr>` ~ s3 ~
			`<tr><td class="group-threads-cell"><div class="group-threads"><table>` ~
			s4 ~ 
			`</table></div></td></tr>` ~
			s5 ~
			`</table>`;
	}
	return result;
}

string testAppendFastJoin()
{
	string result;
	foreach (m; 0..M)
	{
		result ~= fastJoin(
			`FASTJOIN ="group-index" class="forum-table group-wrapper viewmode-`, s1, `">`
			`<tr class="group-index-header"><th><div>`, s2, `</div></th></tr>`, s3,
			`<tr><td class="group-threads-cell"><div class="group-threads"><table>`,
			s4, 
			`</table></div></td></tr>`,
			s5,
			`</table>`);
	}
	return result;
}

string testAppendFastJoinArrInit()
{
	string result;
	foreach (m; 0..M)
	{
		string[11] arr = [
			`<table id="group-index" class="forum-table group-wrapper viewmode-`,
			s1,
			`<tr class="group-index-header"><th><div>`,
			s2,
			`</div></th></tr>`,
			s3,
			`<tr><td class="group-threads-cell"><div class="group-threads"><table>`,
			s4,
			`</table></div></td></tr>`,
			s5,
			`</table>`,
		];
		result ~= fastJoin(arr[]);
	}
	return result;
}

string testAppendFastJoinArrAssign()
{
	string result;
	foreach (m; 0..M)
	{
		string[11] arr = void;
		arr[0] = `<table id="group-index" class="forum-table group-wrapper viewmode-`;
		arr[1] = s1;
		arr[2] = `<tr class="group-index-header"><th><div>`;
		arr[3] = s2;
		arr[4] = `</div></th></tr>`;
		arr[5] = s3;
		arr[6] = `<tr><td class="group-threads-cell"><div class="group-threads"><table>`;
		arr[7] = s4;
		arr[8] = `</table></div></td></tr>`;
		arr[9] = s5;
		arr[10] = `</table>`;
		result ~= fastJoin(arr[]);
	}
	return result;
}

// **************************************************************************************

string testTSingle(T)()
{
	T result;
	foreach (m; 0..M)
	{
		mixin(mixResultPutSingle);
	}
	return cast(string)result.get();
}

string testTMulti(T)()
{
	T result;
	foreach (m; 0..M)
	{
		mixin(mixResultPutMulti);
	}
	return cast(string)result.get();
}

string testStringBuilder2Single () { return testTSingle!StringBuilder2 (); }
string testStringBuilder2SingleX() { return testTSingle!StringBuilder2X(); }

string testStringBuilder2Multi () { return testTMulti !StringBuilder2 (); }
string testStringBuilder2MultiX() { return testTMulti !StringBuilder2X(); }

// **************************************************************************************

string testStringBuilder3Multi () { return testTMulti !StringBuilder3 (); }
string testStringBuilder3MultiX() { return testTMulti !StringBuilder3X(); }

// **************************************************************************************

string testStringBuilder4Multi () { return testTMulti !StringBuilder4 (); }
string testStringBuilder4MultiX() { return testTMulti !StringBuilder4X(); }

// **************************************************************************************

string testStringBuilder5Multi () { return testTMulti !StringBuilder5 (); }
string testStringBuilder5MultiX() { return testTMulti !StringBuilder5X(); }

// **************************************************************************************

string testStringBuilder6Multi () { return testTMulti !StringBuilder6 (); }
string testStringBuilder6MultiX() { return testTMulti !StringBuilder6X(); }
