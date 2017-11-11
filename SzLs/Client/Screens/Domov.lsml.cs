using System;
using System.Linq;
using System.IO;
using System.IO.IsolatedStorage;
using System.Collections.Generic;
using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Framework.Client;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Presentation.Extensions;
using System.Windows.Controls;
namespace LightSwitchApplication
{
	public partial class Domov
	{
		partial void Domov_Created()
		{
			navigateToScreen("Organizacie", this.Application.ShowOrganizaciasListDetail);
			navigateToScreen("Posluchaci", this.Application.ShowPosluchacsListDetail);
			navigateToScreen("Skolenia", this.Application.ShowSkoleniesListDetail);
			navigateToScreen("Zmluvy", this.Application.ShowZmluvasListDetail);
			navigateToScreen("Ulohy", this.Application.ShowUlohasListDetail);
		}

		private void navigateToScreen(string imageName, Action showScreenMethod)
		{
			this.FindControl(imageName).ControlAvailable += (sender, e) =>
			{
				Image image = (Image)e.Control;
				image.Cursor = System.Windows.Input.Cursors.Hand;
				((Image)e.Control).MouseLeftButtonUp += (s, ea) =>
				{
					this.Application.Details.Dispatcher.BeginInvoke(showScreenMethod);
				};
			};
		}
	}
}
