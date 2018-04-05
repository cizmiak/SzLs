<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="default.aspx.cs" Inherits="LightSwitchApplication._default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
	<httpRedirect enabled="true" exactDestination="true" httpResponseStatus="Found">
      <clear />
      <add wildcard="/" destination="Client/default.htm" />
    </httpRedirect>
    </div>
    </form>
</body>
</html>
