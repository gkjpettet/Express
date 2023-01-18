#tag Class
Protected Class MustacheLite
	#tag Method, Flags = &h0
		Sub Constructor()
		  // Initialize the data object.
		  Data = New JSONItem
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Merge()
		  // Merges a template ("Source") with data ("Data"), and stores the result in "Expanded."
		  
		  // Append the system hash to the data hash.
		  If MergeSystemTokens Then
		    SystemDataAppend
		  End If
		  
		  // Load the template.
		  Expanded = Source
		  
		  // Regex used for removal of comments and orphans.
		  Var rg As New RegEx
		  Var rgMatch As RegExMatch
		  
		  // Remove comments.
		  If RemoveComments = True Then
		    rg.SearchPattern = "\{\{!(?:(?!}})(.|\n))*\}\}"
		    rgMatch = rg.Search(Expanded)
		    While rgMatch <> Nil
		      Expanded = rg.Replace(Expanded)
		      rgMatch = rg.Search(Expanded)
		    Wend
		  End If
		  
		  // Loop over the data object's values...
		  For Each key As String In Data.Keys
		    
		    // Get the value.
		    Var value As Variant = Data.Value(key)
		    
		    // If the value is null...
		    If value = Nil Then
		      Continue
		    End If
		    
		    // Use introspection to determine the entry's value type.
		    Var valueType As Introspection.TypeInfo = Introspection.GetType(Value)
		    If valueType = Nil Then Continue
		    
		    // If the value is a boolean, number, string, etc..
		    If valueType.IsPrimitive Then
		      
		      // Convert the primitive value to a string.
		      Var valueString As String = value.StringValue
		      
		      // Using the object's name and the entry's key, generate the token to replace.
		      Var token As String = If(KeyPrefix <> "", KeyPrefix + ".", "") + key
		      
		      // Replace all occurrences of the token with the value.
		      Expanded = Expanded.ReplaceAll("{{" + Token + "}}", valueString)
		      
		      Continue
		      
		    End If
		    
		    // If the value is a nested JSONItem...
		    If valueType.Name = "JSONItem" Then
		      
		      // Get the nested JSONItem.
		      Var nestedJSON As JSONItem = value
		      
		      // If the nested JSONItem is not an array...
		      If nestedJSON.IsArray = False Then
		        
		        // Process the nested JSON using another Template instance. 
		        Var engine As New MustacheLite
		        engine.Source = Expanded
		        engine.Data = nestedJSON
		        engine.KeyPrefix = If(KeyPrefix <> "", KeyPrefix + ".", "") + key
		        engine.MergeSystemTokens = False
		        engine.RemoveComments = False
		        engine.RemoveOrphans = False
		        engine.Merge
		        Expanded = engine.Expanded
		        
		      Else
		        
		        // Get the beginning and ending tokens for this array.
		        Var tokenBegin As String = "{{#" + If(KeyPrefix <> "", KeyPrefix + ".", "") + key + "}}"
		        Var tokenEnd As String = "{{/" + If(KeyPrefix <> "", KeyPrefix + ".", "") + key + "}}"
		        
		        // Get the start position of the beginning token.
		        Var startPosition As Integer = Source.IndexOf(0, tokenBegin) 
		        
		        // Get the position of the ending token.
		        Var stopPosition As Integer = Source.IndexOf(startPosition, tokenEnd)
		        
		        // If the template does not include both the beginning and ending tokens...
		        If ( (startPosition = -1) Or (stopPosition = -1) ) Then
		          // We do not need to merge the array.
		          Continue
		        End If
		        
		        // Get the content between the beginning and ending tokens.
		        Var loopSource As String = Source.Middle( startPosition + tokenBegin.Length, stopPosition - startPosition - tokenBegin.Length)
		        
		        // LoopContent is the content created by looping over the array and merging each value.
		        Var loopContent As String
		        
		        // Loop over the array elements...
		        For i As Integer = 0 to NestedJSON.Count - 1
		          
		          Var arrayValue As Variant = NestedJSON.ValueAt(i)
		          
		          // Process the value using another instance of Template. 
		          Var engine As New MustacheLite
		          engine.Source = loopSource
		          engine.Data = arrayValue
		          engine.KeyPrefix = If(KeyPrefix <> "", KeyPrefix + ".", "") + key
		          engine.MergeSystemTokens = False
		          engine.RemoveComments = False
		          Engine.RemoveOrphans = False
		          Engine.Merge
		          
		          // Append the expanded content with the loop content.
		          loopContent = loopContent + engine.Expanded
		          
		        Next i
		        
		        // Substitute the loop content block of the template with the expanded content.
		        Var loopBlock As String = tokenBegin + loopSource + tokenEnd
		        Expanded = Expanded.ReplaceAll(loopBlock, loopContent)
		        
		      End If
		      
		      Continue
		      
		    End If
		    
		    // This is an unhandled value type.
		    // In theory, we should never get this far.
		    // Look at ValueType.Name to determine what the type is.
		    Break
		    
		  Next key
		  
		  // Remove orphaned tokens.
		  If RemoveOrphans = True Then
		    rg.SearchPattern = "\{\{(?:(?!}}).)*\}\}"
		    rgMatch = rg.Search(Expanded)
		    While rgMatch <> Nil
		      Expanded = rg.Replace(Expanded)
		      rgMatch = rg.Search(Expanded)
		    Wend
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SystemDataAppend()
		  // Initialize the system object, which is used to merge system tokens.
		  Var systemData As New JSONItem
		  
		  // Append the system object to the data object.
		  Data.Value("system") = SystemData
		  
		  // Add the Date object.
		  Var dateData As New JSONItem
		  Var today As DateTime = DateTime.Now
		  dateData.Value("abbreviateddate") = today.ToString( Nil, DateTime.FormatStyles.Medium, DateTime.FormatStyles.None )
		  dateData.Value("day") = today.Day.ToString
		  dateData.Value("dayofweek") = today.DayOfWeek.ToString
		  dateData.Value("dayofyear") = today.DayOfYear.ToString
		  Var GMTOffset As Double = today.Timezone.SecondsFromGMT / 3600 //3600 seconds in an hour
		  dateData.Value("gmtoffset") = GMTOffset.ToString
		  dateData.Value("hour") = today.Hour.ToString
		  dateData.Value("longdate") = today.ToString( Nil, DateTime.FormatStyles.Long, DateTime.FormatStyles.None )
		  dateData.Value("longtime") = today.ToString( Nil, DateTime.FormatStyles.None, DateTime.FormatStyles.Medium ) // This is the closest equivalent to the old code. We might have to trip the AM and PM off the end
		  dateData.Value("minute") = today.Minute.ToString
		  dateData.Value("month") = today.Month.ToString
		  dateData.Value("second") = today.Second.ToString
		  dateData.Value("shortdate") = today.ToString( Nil, DateTime.FormatStyles.Short, DateTime.FormatStyles.None )
		  dateData.Value("shorttime") = today.ToString( Nil, DateTime.FormatStyles.None, DateTime.FormatStyles.Short )
		  dateData.Value("sql") = today.SQLDate
		  dateData.Value("sqldate") = today.SQLDate
		  dateData.Value("sqldatetime") = today.SQLDateTime
		  dateData.Value("SecondsFrom1970") = today.SecondsFrom1970
		  dateData.Value("weekofyear") = today.WeekOfYear.ToString
		  dateData.Value("year") = today.Year.ToString
		  systemData.Value("date") = dateData
		  
		  // Add the Meta object.
		  Var metaData As New JSONItem
		  metaData.Value("xojo-version") = XojoVersionString
		  metaData.Value("express-version") = Express.VERSION_STRING
		  systemData.Value("meta") = metaData
		  
		  
		  // Add the Request object.
		  Var RequestData As New JSONItem
		  Var cookiesJSON As JSONItem = Request.Cookies
		  RequestData.Value("cookies") = cookiesJSON
		  RequestData.Value("data") = Request.Data
		  Var getParamsJSON As JSONItem = Request.GET
		  RequestData.Value("get") = getParamsJSON
		  Var headersJSON As JSONItem = Request.Headers
		  RequestData.Value("headers") = headersJSON
		  RequestData.Value("method") = Request.Method
		  RequestData.Value("path") = Request.Path
		  Var postParamsJSON As JSONItem = Request.POST
		  RequestData.Value("post") = postParamsJSON
		  RequestData.Value("remoteaddress") = Request.RemoteAddress
		  RequestData.Value("socketid") = Request.SocketID
		  RequestData.Value("urlparams") = Request.URLParams
		  SystemData.Value("request") = RequestData
		  
		  
		  
		  
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		Data As JSONItem
	#tag EndProperty

	#tag Property, Flags = &h0
		Expanded As String
	#tag EndProperty

	#tag Property, Flags = &h0
		KeyPrefix As String
	#tag EndProperty

	#tag Property, Flags = &h0
		MergeSystemTokens As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		RemoveComments As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		RemoveOrphans As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		Request As Express.Request
	#tag EndProperty

	#tag Property, Flags = &h0
		Source As String
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="KeyPrefix"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Source"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Expanded"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemoveOrphans"
			Visible=false
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemoveComments"
			Visible=false
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="MergeSystemTokens"
			Visible=false
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
