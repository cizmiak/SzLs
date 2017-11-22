using Microsoft.LightSwitch.Presentation.Extensions;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Framework.Client;
using Microsoft.LightSwitch;
using System.Collections.Generic;
using System.IO.IsolatedStorage;
using System.IO;
using System.Linq;
using System;
using Microsoft.LightSwitch.Threading;
using System.Windows.Controls;

namespace LightSwitchApplication
{
	public partial class GetXlsxSheetsById
	{
		partial void GetXlsxSheetsById_Created()
		{
			this.FindControl("XlsxImport").ControlAvailable += XlsxImport_ControlAvailable;
		}

		private void XlsxImport_ControlAvailable(object sender, ControlAvailableEventArgs e)
		{
			((Button)e.Control).Click += XlsxImport_Click;
		}

		private void XlsxImport_Click(object sender, System.Windows.RoutedEventArgs e)
		{
			byte[] bytes = null;

			Dispatchers.Main.Invoke(() => {
				var dialog = new OpenFileDialog();
				dialog.Filter = "Excel(*.xlsx)|*.xlsx";

				if (dialog.ShowDialog() == true)
				{
					using (var fileStream = dialog.File.OpenRead())
					{
						int fileLength = (int)fileStream.Length;
						if (fileStream.Length > 0)
						{
							bytes = new byte[fileLength];
							fileStream.Read(bytes, 0, fileLength);
						}

						fileStream.Close();
					}
				}
			});

			var id = Guid.NewGuid();
			this.Details.Dispatcher.BeginInvoke(() =>
			{
				
				var xlsxByte = this.DataWorkspace.XlsxReaderServiceData.XlsxBytes.AddNew();
				xlsxByte.Id = id;
				xlsxByte.Bytes = bytes;
				this.DataWorkspace.XlsxReaderServiceData.SaveChanges();

				//var xlsxRows = this.DataWorkspace.XlsxReaderServiceData.GetXlsxRowsById(id).Execute();
			});

			this.XlsxId = id;
		}
	}
}