using Microsoft.LightSwitch;
using System.Text;
using System.Linq;
using System.Collections.Generic;
using System;

namespace LightSwitchApplication
{
	public partial class SkoleniePosluchac
	{
		public void CopyFrom(SkoleniePosluchac skoleniePosluchac)
		{
			if (skoleniePosluchac == null)
			{
				return;
			}

			foreach (var property in skoleniePosluchac.Details.Properties.All())
			{
				if (!property.IsReadOnly)
				{
					this.Details.Properties[property.Name].Value = property.Value;
				}
			}
		}
	}
}