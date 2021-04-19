------------------------------------------------------------------------------------------
-- 64 registry key stuff
------------------------------------------------------------------------------------------

function dbgout(a,b) 

end

function AddBS( cPath )
  String.TrimRight(cPath,nil);
	if String.Length(cPath) > 0 and String.Right(cPath,1) ~= "\\" then
  	cPath = cPath .. "\\"
	end
  return cPath
end

--[[

FUNCITON: String.RandomFromPattern

PURPOSE: To return a random string based on a given pattern.

PARAMETERS: Pattern (string) - The pattern to base the random string on.
				Interpreted as follows:
				
				# - A random digit (0-9)
				* - A random uppercase letter (A-Z)
				@ - A random lowercase letter (a-z)
				? - A random digit or uppercase letter (0-9,A-Z)
				~ - A random digit, upppercase or lowercase letter (0-9,A-Z,a-z)
				Any other charater - Remains the same.
				
RETURNS: A randomized string.

EXAMPLES:

String.RandomFromPattern("###-###"); -- could produce: "6355-0989"
String.RandomFromPattern("TEST-***"); -- could produce: "TEST-HAJ"
String.RandomFromPattern("~~~~~~~~~~"); -- could produce: "7Hg543fp02"

]]

function String.RandomFromPattern(Pattern)
	local strReturn = "";
	local tblAlphabet = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N",
						 "O","P","Q","R","S","T","U","V","W","X","Y","Z"};

	-- Seed the random number engine with the current time...
	local nRandomSeed = 0;
	nRandomSeed = String.ToNumber(System.GetTime(TIME_FMT_HOUR));
	nRandomSeed = nRandomSeed * String.ToNumber(System.GetTime(TIME_FMT_MIN));
	nRandomSeed = nRandomSeed * String.ToNumber(System.GetTime(TIME_FMT_SEC));
	Math.RandomSeed(nRandomSeed);
	
	local nStringLength = String.Length(Pattern);
	
	for i = 1,nStringLength do
		local nChar = String.Mid(Pattern,i,1);
		
		if(nChar == "#")then
			-- Number
			nChar = Math.Random(0,9);	
		elseif(nChar == "*")then
			-- Uppercase letter
			nChar = tblAlphabet[Math.Random(1,26)];
		elseif(nChar == "@")then
			-- Lowercase letter
			nChar = String.Lower(tblAlphabet[Math.Random(1,26)]);
		elseif(nChar == "?")then
			-- Number or Uppercase letter
			local nCoinToss = Math.Random(1,2);
			if(nCoinToss == 1)then
				-- Number
				nChar = Math.Random(0,9);
			else
				-- Uppercase Letter
				nChar = tblAlphabet[Math.Random(1,26)];
			end
		elseif(nChar == "~")then
			-- Number or Uppercase letter or Lowercase Letter
			local nCoinToss = Math.Random(1,3);
			if(nCoinToss == 1)then
				-- Number
				nChar = Math.Random(0,9);
			elseif(nCoinToss == 2)then
				-- Uppercase Letter
				nChar = tblAlphabet[Math.Random(1,26)];
			else
				-- Lowercase letter
				nChar = String.Lower(tblAlphabet[Math.Random(1,26)]);
			end
		end
		
		strReturn = strReturn..nChar;
	end
	
	return strReturn;
end


-- 64Bit Registry Support by jAssing (c) 2007-2010 Josh Assing
-- support@jAssing.com

-- This 'fixes' issues with the registry on 64bit machines
-- all functions are the same, so you can use the intelisense
-- and then change Registry. to Registry64.
-- this is not a complete "replacement" set yet.
-- On 32bit machines, it uses the default actions so it doesn't slow that down.

-- This uses code by Brett
-- http://www.indigorose.com/forums/showthread.php?t=9277
-- as well as code by Eagle -- he's posted it many places, and is included in the zip file here.

RegUseExe = true;

function RegEdit( nHive, cKey, cValue, xData, nType)
  if System.Is64BitOS() and Registry64.UseExe then
		dbgout("RegEdit");
		local cParam = " /f";
		if type(cValue) == "string" then
			local cVP = " /v "..cValue ;
			if type(xData)=="string" and String.Find( xData, " ")>0 then
			  xData = "\"" .. xData .. "\"";
			end
			if String.Length(cValue) == 0 then
				cVP = " /ve ";
			end
			cParam = cParam .. cVP .. " /t "..RegGetType( nType ) .. " /d "..xData;
		end
		-- -- assert(nHive)
		RunReg( nHive, "add", cKey, cParam )
	else
		if type(cValue) == "string" then
			Registry.SetValue( nHive, cKey, cValue, xData, nType);
		else
			Registry.CreateKey( nHive, cKey );
		end
	end
end

function RegDelete(nHive, cKey, cValue)
  if System.Is64BitOS() and Registry64.UseExe then
		local cParam =" /f";
		dbgout("RegDelete");
		if type(cValue) == "string" then
			if String.Length(cValue) == 0 then
				cParam = cParam .. " /ve";
			else
				cParam = " /v "..cValue .. cParam;
			end
		end
		-- -- assert(nHive)
		RunReg( nHive, "delete", cKey, cParam);
	else
		if type(cValue) == "string" then
			Registry.DeleteValue( nHive, cKey, cValue );
		else
			Registry.DeleteKey( nHive, cKey );
		end
	end
end

function RegGetValueNames( nHive, cKey )
	local tValues = {};
	if System.Is64BitOS() and Registry64.UseExe then
		local cTemp = File.TempFileName();
		dbgout("RegGetValueNames");
		-- -- assert(nHive)
		if RunReg( nHive, "query", cKey, "",cTemp) ==0 then
			local tFile = RegReadToTable( cTemp );
			if tFile and type(tFile) == "table" then
				local x = 0;
				for x = 1, Table.Count( tFile ) do
				  if String.Left( tFile[x], 4 ) == String.Repeat(' ',4) then
				    local nTab = String.Find( tFile[x], "\t");
				    if nTab > 0 then
				    	local cValue = String.Mid( tFile[x], 5, nTab-5);
				    	if cValue == "<NO NAME>" then
				    	  cValue = "(Default)";
				    	end
				    	Table.Insert(tValues, Table.Count( tValues) + 1, cValue);
				    end
				  end
				end
			else
				-- Not a table, no values -- empty default
				Table.Insert(tValues, 1, "(Default)");
			end
		else
			RegDeleteFile(cTemp);
		end
		if Table.Count( tValues ) == 0 then
		  tValues = nil;
		end
	else
		tValues = Registry.GetValueNames(nHive, cKey);
	end
	return tValues;
end

function RegGetKeyNames( nHive, cKey )
	local tNames = {};
	if System.Is64BitOS() and Registry64.UseExe then
		local cTemp = File.TempFileName();
		dbgout("RegGetKeyNames");
		-- -- assert(nHive)
		if RunReg( nHive, "query", cKey, "",cTemp) ==0 then
			local tFile = RegReadToTable( cTemp );
			if tFile and type(tFile) == "table" then
				local x = 0;
				for x = 1, Table.Count( tFile ) do
				  if String.Find( tFile[x], cKey.."\\",1,false) > 0 then
				    local cSubKey = String.Right( tFile[x], (String.Length(tFile[x])-String.ReverseFind( tFile[x], "\\")));
				    Table.Insert(tNames, Table.Count( tNames) + 1, cSubKey);
				  end
				end
			end
		else
			RegDeleteFile(cTemp);
		end
		if Table.Count( tNames ) == 0 then
		  tNames = nil;
		end
	else
		tNames = Registry.GetKeyNames(nHive, cKey);
	end
	return tNames;
end

function RegGetValueType( nHive, cKey, cValue )
  local nType = -1;
  if System.Is64BitOS() and Registry64.UseExe then
	  local cTemp = File.TempFileName();
	  dbgout("RegGetValueType");
	  -- -- assert(nHive)
	  if RunReg( nHive, "query", cKey," /v "..cValue,cTemp) ==0 then
	    local tFile = RegReadToTable( cTemp );
	    if tFile and type(tFile) == "table" then
		    local cLine = tFile[5];
		    local nTab = String.Find( cLine, "\t", 1, false);
		    if nTab ~= -1 then
		      local nTab2 = String.Find( cLine, "\t", nTab+1, false);
		      if nTab2 ~= 1 then
		    		local cType = String.Mid( cLine, nTab+1, nTab2-nTab-1 );
		    		nType = RegGetType( cType );
		    	end
		    end
	    end
	  else
			RegDeleteFile(cTemp);
		end
	else
		nType = Registry.GetValueType(nHive, cKey, cValue);
	end
  return nType;
end

function RegGetValue( nHive, cKey, cValue, bExpand )
  local cData = nil;
  local nError = 1;
  local nReturn = -1;
  if System.Is64BitOS() and Registry64.UseExe then
	  local cTemp = File.TempFileName();
	  dbgout("RegGetValue");
	  if String.Length(cValue) == 0 then
	  	-- -- assert(nHive)
	  	nReturn = RunReg( nHive, "query", cKey, " /ve",cTemp);
	  else
	  	-- -- assert(nHive)
	  	nReturn = RunReg( nHive, "query", cKey, " /v "..cValue,cTemp);
	  end
	  if nReturn == 0 then
	    local tFile = RegReadToTable( cTemp );
	    if tFile and type(tFile) == "table" then
		    local cLine = tFile[5];
		    local nTab = String.Find( cLine, "\t", 1, false);
	   		if nTab ~= -1 then
		      nTab = String.Find( cLine, "\t", nTab+1, false);
		      if nTab ~= 1 then
		    		cData = String.Mid( cLine, nTab+1, String.Length(cLine) );
		    		cData = RegStrTran(cData,"\\0", "|");
		    		nError = 0;
		    	end
		    end
		  end
	  else
			RegDeleteFile(cTemp);
	  end
	else
		if type(bExpand) ~= "boolean" then
			bExpand = false;
		end
		cData = Registry.GetValue(nHive, cKey, cValue, bExpand);
		nError = Application.GetLastError();
	end

	if type(cData) ~= "string" then
		cData = "";
		nError = 1;
	end
	if System.Is64BitOS() and Registry64.UseExe then
		if type(nError) == "string" then
			dbgout("Converting err to string", nError);
			nError = String.ToNumber( nError );
		end

		if type(nError) == "number" then
			--SetupData.WriteToLogFile( "Info\tIgnore the following error\r\n",true);
			Application.SetLastError(nError);
		else
			dbgout("Not numer for sle",nError);
		end
	end
  return cData;
end

function RegDoesKeyExist( nHive, cKey )
	local bIsThere = false;
	if System.Is64BitOS() and Registry64.UseExe then
		dbgout("RegDoesKeyExist");
		-- -- assert(nHive)
		bIsThere = (RunReg( nHive, "query", cKey, " /ve" ) == 0);
	else
		-- -- assert(nHive)
	  bIsThere = Registry.DoesKeyExist( nHive, cKey);
	end
	return bIsThere;
end

function RegReadToTable( cFile )
	local tData = nil;
	if File.DoesExist( cFile ) then
	  tData = TextFile.ReadToTable( cFile );
		RegDeleteFile(cFile);
		if tData and type(tData) == "table" and Table.Count(tData) > 3 then
			if tData[2] == "! REG.EXE VERSION 3.0" then
				-- Do nothing; this is the 'standard' format for these tools are based
			else -- Here's where we deal with 'no version'
			  local cVersion = File.GetVersionInfo( _SystemFolder .. "\\reg.exe" ).FileVersion;
			  local nDot = String.Find( cVersion, '.');
			  if nDot > 0 then
			  	cVersion = String.Left( cVersion, nDot - 1);
			  end
				Table.Insert( tData, 1, " ");
				Table.Insert( tData, 2, "! REG.EXE VERSION "..cVersion);
				local x = 0;
				for x = 1, Table.Count( tData ) do
					tData[x] = RegStrTran( tData[x], String.Repeat(' ',4), "\t", false);
					if String.Left(tData[x],1)=="\t" then
						tData[x] = String.Repeat(' ',4) .. String.Mid( tData[x],2, String.Length( tData[x] ) );
					end
					local nRegBinary = String.Find( tData[x], "REG_BINARY");
					if nRegBinary > 0 then
						-- we need to 'fix' to be properly spaced.
						local cBinVal = String.Mid( tData[x], nRegBinary+11, String.Length(tData[x]) );
						local cNewVal = "";
						-- Now let's space out the regbinary value
						local j=0;
						for j=1, String.Length( cBinVal ), 2 do
						  cNewVal = cNewVal..String.Mid( cBinVal, j, 2) .. " ";
						end
						if String.Length( cNewVal ) ~= Math.Floor( String.Length(cNewVal)/2) then
							-- Needs to be ## ## ## ## so we need to add a zero
							cNewVal = '0'..cNewVal;
						end
						tData[x] = RegStrTran( tData[x], cBinVal, cNewVal);
					end
					local nDWord = String.Find( tData[x], "REG_DWORD");
					if nDWord > 0 then
						local cOldVal = String.Mid( tData[x], nDWord+10, String.Length( tData[x] ) );
						if String.Length(cOldVal) > 0 then
							local cNewVal = RegHexToNum( cOldVal );
							tData[x] = RegStrTran( tData[x], cOldVal, cNewVal);
						end
					end
				end
			end
			-- -- assert( String.Left( tData[2], 1) == "!", "Unknown Reg output "..cFile);
			-- -- assert( Table.Count(tData)>=5, "Bad Table");
		else
			dbgout("Table Invalid -- no values to list");
		end
	end
	return tData
end

-- Support Functions
function RegGetHive( nHive )
  -- -- assert(nHive)
	local cHive = "";
	local tHive = { "HKCR", "HKCC", "HKCU", "HKLM", "HKU"};
	if nHive then
		nHive = nHive + 1;
	else
		nHive = 2 -- Default to HKLM
	end
	if nHive > 0 and nHive <= Table.Count( tHive ) then
	  cHive = tHive[nHive];
	end
	return cHive;
end

function RegGetType( xFindType )
  local tTypes = {"REG_NONE", "REG_SZ", "REG_EXPAND_SZ", "REG_BINARY", "REG_DWORD", "REG_DWORD_LITTLE_ENDIAN", "REG_DWORD_BIG_ENDIAN", "REG_LINK", "REG_MULTI_SZ", "REG_RESOURCE_LIST", "REG_FULL_RESOURCE_DESCRIPTOR", "REG_RESOURCE_REQUIREMENTS_LIST"};
  local xFoundType = nil;
  local x = 0;
  if type(xFindType) == "string" then
	  for x=1, Table.Count( tTypes ) do
	    if xFindType == tTypes[x] then
	      xFoundType = x-1;
	      x=Table.Count(tTypes);
	    end
	  end
	else
		xFoundType = tTypes[ xFindType+1 ];
	end
  return xFoundType;
end

function RunReg( nHive, cCMD, cLine, cXtra, cOutput )
	-- -- assert(nHive)

	local cParam = RegGetHive(nHive);
	local nResult = -1;

	if String.Right( cParam, 1) == "\\" then
	  cParam = String.Left( cParam, String.Length( cParam ) - 1);
	end

	cParam = AddBS( cParam ) .. cLine;

	if String.Right( cParam, 1) == "\\" then
	  cParam = String.Left( cParam, String.Length( cParam ) - 1);
	end

	if String.Find( cParam, " ") > 0 then
	  cParam = "\"" .. cParam .. "\"";
	end
	if type(cXtra)=="string" then
		cParam = cParam .. cXtra;
	end
	-- -- assert( File.DoesExist( _SystemFolder .. "\\reg.exe" ), "Missing ".._SystemFolder.."\\Reg.exe");
	if cOutput then
		-- -- assert( File.DoesExist( _SystemFolder .. "\\cmd.exe" ), "Missing cmd.exe");
		wow64.disable();
		dbgout("Running Command: Reg.exe "..cCMD .." "..cParam.." >"..cOutput);
		nResult = File.Run(_SystemFolder.."\\cmd.exe","/c ".._SystemFolder.."\\Reg.exe "..cCMD .." "..cParam.." >"..cOutput,_SystemFolder, -1, true);
		wow64.enable();
		RegDeleteFile(cBatchFile);
	else
		wow64.disable();
		dbgout("Running Reg.exe "..cCMD .. " "..cParam);
		nResult = File.Run(_SystemFolder.."\\Reg.exe", cCMD .. " "..cParam, _SystemFolder, -1, true);
		wow64.enable();
	end

	if type(nResult) == "string" then
		dbgout("Converting err to string", nResult);
		nError = String.ToNumber( nResult );
	end

	if type(nResult) == "number" then
		--SetupData.WriteToLogFile( "Info\tIgnore the following error\r\n",true);
		Application.SetLastError(nResult);
	else
		dbgout("SetLastError - failed, not number",nResult);
	end

	dbgout("Returning "..nResult);
	return nResult;
end

function RegDeleteFile( cFile )
  if type(cFile) == "string" and File.DoesExist( cFile ) then
  	File.Delete( cFile,false,false,false,RegNoCallBack );
  	if File.DoesExist( cFile ) then
  		File.DeleteOnReboot( cFile );
  	end
  end
end

function RegNoCallBack()
return true;
end
function RegHexToNum( cNum )
	local nReturn = cNum;
  if type(nReturn) == "string" then
  	nReturn = String.TrimLeft( String.TrimRight( nReturn ));
    if String.CompareNoCase(String.Left(nReturn,2), "0x") == 0 then
	    nReturn = String.Mid( nReturn, 3, String.Length( nReturn ) -2);
	    nReturn = Math.HexToNumber( nReturn );
	  end
  end
  return nReturn;
end

function RegStrTran( cString, cFind, cNew, bCaseSpecific )
  local cNewString = cString;
  if type(bCaseSpecific) ~= "boolean" then
    bCaseSpecific  = true;
  end
  if type(cFind)=="string" and type(cString)=="string" and String.Length(cString) > 0 and String.Length(cFind) > 0 and cString ~= cFind then
  	local nFind = String.Find( cString, cFind, 1, bCaseSpecific );
	  local nLastFind = -1; -- prevent endless loops
	  while nFind > 0 and nFind ~= nLastFind do
	  	local cTemp = String.Left( cNewString, nFind-1 );
			cTemp = cTemp .. cNew;

			cTemp = cTemp .. String.Mid( cNewString, nFind+String.Length(cFind), String.Length(cNewString));
			cNewString = cTemp;
			nLastFind = nFind;
	 		nFind = String.Find( cNewString, cFind, 1, bCaseSpecific );
		end
	end
	return cNewString;
end

function RegGetTempFileName( cExtension )
	-- This uses 'random' code by Brett, see post http://www.indigorose.com/forums/showthread.php?t=9277
  local cFile = "";
  if not cExtension then
    cExtension = "tmp";
  end
	repeat -- Keep going until a new random filename is found
		cFile = _TempFolder.."\\"..String.RandomFromPattern("r64?????."..cExtension);
	until not File.DoesExist( cFile );
	return cFile;
end

function RegImport( cFile )
	local nResult = -1;

	if System.GetOSName() == "Windows 2000" then
		if File.DoesExist( _WindowsFolder.."\\regedit.exe" ) then
		  nResult = File.Run( _WindowsFolder.."\\regedit.exe", "/s "..cFile, _WindowsFolder, -1, true, true);
		else
	  	File.Open( cFile );
	  	nResult = 0;
	  end
  else
		-- -- assert( File.DoesExist( _SystemFolder .. "\\reg.exe" ), "Missing Reg.exe");
		if File.DoesExist( cFile ) then
			wow64.disable();
			dbgout("Importing",cFile);
			nResult = File.Run(_SystemFolder.."\\Reg.exe","import "..cFile, _SystemFolder, -1, true, true);
			dbgout("Result of import "..nResult);
			wow64.enable();
		else
			dbgout("Can't import, file missing",cFile);
		end
  end
	return nResult;
end

-- Object Creation
Registry64={};
Registry64.CreateKey		= RegEdit;
Registry64.DeleteKey		= RegDelete;
Registry64.DeleteValue	= RegDelete;
Registry64.DoesKeyExist = RegDoesKeyExist;
-- Registry64.GetAccess	=	 ??
Registry64.GetKeyNames 	= RegGetKeyNames;
Registry64.GetValue 		= RegGetValue;
Registry64.GetValueNames= RegGetValueNames;
Registry64.GetValueType = RegGetValueType;
Registry64.SetValue			= RegEdit;
Registry64.Import				= RegImport;

File.TempFileName 			= RegGetTempFileName;
Registry64.UseExe				= RegUseExe

-- The following wow64 code is by Eagle -- look thru the IR forums -- it's posted all over the place.
-- Modified by jAssing

--sWOW64 DIS-EN
wow64={}
wow64.enabled=nil
wow64.SleepTime = 50;

if System.Is64BitOS then
  dbgout("WOW64: Initialize")
  wow64.enabled=true
  -- this will always be 'nil' to indicate x86 OS.
end

function wow64.disable()
	if System.Is64BitOS() then
	  if wow64.enabled then
			dbgout("WOW64: Disabling Wow64 Redirect");
			Application.SetLastError(0);
			local nOut = DLL.CallFunction("kernel32.dll", "Wow64DisableWow64FsRedirection", "\""..Application.GetWndHandle().."\"", DLL_RETURN_TYPE_LONG, DLL_CALL_STDCALL);
			local nErr = Application.GetLastError();
		  dbgout("Disabled",_tblErrorMessages[ nErr].."("..nErr..") ["..nOut.."]");
			Application.Sleep(wow64.SleepTime); 
			wow64.enabled = false;
		else
			dbgout("WOW64: NOT Disabling Wow64 Redirect");
		end	
	end
end

function wow64.enable()
	if System.Is64BitOS() then
	  if not wow64.enabled then
			dbgout("WOW64: Enabling Wow64 Redirect");
			Application.SetLastError(0);
			local nOut = DLL.CallFunction("kernel32.dll", "Wow64RevertWow64FsRedirection", "\""..Application.GetWndHandle().."\"" , DLL_RETURN_TYPE_LONG, DLL_CALL_STDCALL);
			local nErr = Application.GetLastError();
			dbgout("Enabled",_tblErrorMessages[ nErr ] .."("..nErr..") ["..nOut.."]");
			Application.Sleep(wow64.SleepTime); 
			wow64.enabled = true;
		else
			dbgout("WOW64: NOT Enabling Wow64 Redirect");
		end
	end
end

--eWOW64 DIS-EN
