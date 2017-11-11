using System;
using System.Linq;
using System.IO;
using System.IO.IsolatedStorage;
using System.Collections.Generic;
using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Framework.Client;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Presentation.Extensions;
namespace LightSwitchApplication
{
    public partial class UlohasListDetail
    {
		private string ulohaStavVyrieseneString;
		public string UlohaStavVyrieseneString
		{
			get
			{
				if (ulohaStavVyrieseneString == null)
				{
					ulohaStavVyrieseneString = this.DataWorkspace.SpravaZmluvData
						.KonfiguracnaHodnota("UlohaStavVyriesene").FirstOrDefault().Hodnota;
				}
				return ulohaStavVyrieseneString;
			}
		}

		partial void UlohasListDetail_Created()
		{
			this.LenNevyriesene = true;
		}

		partial void LenNevyriesene_Changed()
		{
			if (this.LenNevyriesene)
			{
				this.UlohaStavVyriesene = UlohaStavVyrieseneString;
			}
			else
			{
				this.UlohaStavVyriesene = null;
			}
		}
	}
}
