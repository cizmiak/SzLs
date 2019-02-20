using System;
using Microsoft.LightSwitch.Presentation;
using System.Runtime.InteropServices.Automation;
using Microsoft.LightSwitch.Threading;
using System.Windows.Browser;
using System.Windows.Threading;
using System.Windows.Controls;

namespace LightSwitchApplication
{
	public partial class Application
	{
		private bool isCurrentUserAdministrator = false;
		public bool IsCurrentUserAdministrator
		{
			get { return isCurrentUserAdministrator; }
		}

		private bool isCurrentUserPowerUser = false;
		public bool IsCurrentUserPowerUser
		{
			get { return isCurrentUserPowerUser; }
		}

		private Zamestnanec prihlasenyZamestnanec;
		public Zamestnanec PrihlasenyZamestnanec
		{
			get { return prihlasenyZamestnanec; }
		}

		partial void Application_LoggedIn()
		{
			DataWorkspace dws = this.CreateDataWorkspace();
			prihlasenyZamestnanec = dws.SpravaZmluvData.ZamestnanecPodlaLoginu(this.User.Name);

			if (PrihlasenyZamestnanec != null && PrihlasenyZamestnanec.Rola != null)
			{
				isCurrentUserAdministrator = (PrihlasenyZamestnanec.Rola.Nazov == "administrator");
				isCurrentUserPowerUser = (PrihlasenyZamestnanec.Rola.Nazov == "power user");
			}

			dws.Dispose();
		}

		partial void KonfiguraciasListDetail_CanRun(ref bool result)
		{
			// Set result to the desired field value
			result = IsCurrentUserAdministrator;
		}

		partial void Zamestnanci_CanRun(ref bool result)
		{
			// Set result to the desired field value
			result = IsCurrentUserAdministrator;

		}

		internal static void navigateUri(string uri)
		{
			Dispatchers.Main.BeginInvoke(() =>
			{
				if (AutomationFactory.IsAvailable)
				{
					dynamic shell = AutomationFactory.CreateObject("Shell.Application");
					shell.ShellExecute(uri);
				}
				else if (!System.Windows.Application.Current.IsRunningOutOfBrowser)
				{
					HtmlPage.Window.Navigate(new Uri(uri), "_blank");
				}
				else
				{
					throw new InvalidOperationException();
				}
			}); 
		}

		internal static void updateSourceAfterLastKeyUp(object sender, ControlAvailableEventArgs e)
		{
			DateTime lastKeyUpDate;
			DispatcherTimer timer = new DispatcherTimer();
			bool tickRegistered = false;
			int waitTimeToRefresh = 1000;

			((TextBox)e.Control).KeyUp += (object textboxObject, System.Windows.Input.KeyEventArgs eventArgs) =>
			{
				if (timer.IsEnabled)
				{
					timer.Stop();
				}

				lastKeyUpDate = DateTime.Now;
				timer.Interval = TimeSpan.FromMilliseconds(waitTimeToRefresh);

				if (!tickRegistered)
				{
					tickRegistered = true;
					timer.Tick += (object timerObject, EventArgs ea) =>
					{

						if ((DateTime.Now - lastKeyUpDate).TotalMilliseconds >= waitTimeToRefresh)
						{
							((TextBox)textboxObject).GetBindingExpression(TextBox.TextProperty).UpdateSource();
						}

						if (((DispatcherTimer)timerObject).IsEnabled)
						{
							((DispatcherTimer)timerObject).Stop();
						}
					};
				}

				timer.Start();
			};
		}

		partial void CiselnikyOrganizacie_CanRun(ref bool result)
		{
			result = Ciselniky_CanRun;
		}

		partial void CislenikyZmluv_CanRun(ref bool result)
		{
			result = Ciselniky_CanRun;
		}

		partial void CiselnikyUlohy_CanRun(ref bool result)
		{
			result = Ciselniky_CanRun;
		}

		partial void CiselnikySkolenia_CanRun(ref bool result)
		{
			result = Ciselniky_CanRun;
		}

		partial void CiselnikyOstatne_CanRun(ref bool result)
		{
			result = Ciselniky_CanRun;
		}

		private bool Ciselniky_CanRun
		{
			get
			{
				return (IsCurrentUserAdministrator || IsCurrentUserPowerUser);
			}
		}
	}
}
