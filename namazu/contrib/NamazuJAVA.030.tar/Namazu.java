import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;

public class Namazu extends Frame implements ItemListener, ActionListener, KeyListener {
  MenuBar mbar;
  Menu file_menu, edit_menu, view_menu, options_menu;
  Menu browser_select_menu, help_menu;
  MenuItem file_open, file_save, file_quit;
  MenuItem edit_conf;
  MenuItem view_usage, view_conf, view_hist;
  MenuItem browser_select, item_netscape, item_lynx, item_mosaic, item_mmm;
  MenuItem version_info; //help_item;

  TextField key_input, dir_input;
  TextArea output;
  Choice number_choice, summary_choice, format_choice, sort_choice;
  Label key_input_label, dir_label, number_label, summary_label;
  Label format_label, sort_label;
  Panel p0, p1, p2, p3, p4;
  Button b_ok, b_clear;
  String key_buf, dir_buf, number_buf, summary_buf, format_buf, sort_buf;

  private String filename = null;
  String cmd_option = "";
  String netscape_options;

  final static private String NETSCAPE_CMD = "/usr/local/bin/netscape";
  final static private String NAMAZU_CMD = "/usr/local/bin/namazu";
  final static private String result_html = "/tmp/NAMAZU_WORK.html";

  /* add Jul.10.1998 */
  final static private String J = " -L ja";
  final static private String E = " -L en";

  static boolean first_conf = true;
  static boolean first_hist = true;

  NamazuHistory namazuhist_window;

  ResourceBundle namazuResources =
    ResourceBundle.getBundle ("NamazuResources");
  String lf = System.getProperty ("line.separator", "");

  /* キー制御用スタティック変数 */
  static private int cspace = 0;
  static private int now_cur;

  static private String paste_buf;
  static private String before;
  static private String after;

  public void init () {
	mbar = new MenuBar ();
	setMenuBar (mbar);

	file_menu = new Menu (namazuResources.getString ("FILE"));
	mbar.add (file_menu);
	file_open = new MenuItem (namazuResources.getString ("Open"));
	file_save = new MenuItem (namazuResources.getString ("Save"));
	file_quit = new MenuItem (namazuResources.getString ("Quit"));
	file_open.addActionListener (this);
	file_save.addActionListener (this);
	file_quit.addActionListener (this);
	file_menu.add (file_open);
	file_open.setEnabled (false);
	file_menu.add (file_save);
	file_menu.add (file_quit);

	edit_menu = new Menu (namazuResources.getString ("EDIT"));
	mbar.add (edit_menu);
	edit_conf = new MenuItem (namazuResources.getString ("ConfigFile"));
	edit_conf.addActionListener (this);
	edit_menu.add (edit_conf);

	view_menu = new Menu (namazuResources.getString ("VIEW"));
	// view_menu.setEnabled (false);
	mbar.add (view_menu);
	view_usage = new MenuItem (namazuResources.getString ("Usage"));
	view_conf = new MenuItem (namazuResources.getString ("Configration"));
	view_hist = new MenuItem (namazuResources.getString ("History"));

	view_usage.addActionListener (this);
	view_conf.addActionListener (this);
	view_hist.addActionListener (this);
	view_menu.add (view_usage);
	view_menu.add (view_conf);
	view_menu.add (view_hist);

	options_menu = new Menu (namazuResources.getString ("OPTIONS"));
	mbar.add (options_menu);
	browser_select_menu = new Menu (namazuResources.getString ("Browser"));
	options_menu.add (browser_select_menu);
	browser_select_menu.addActionListener (this);
	item_netscape = new MenuItem ("netscape");
	item_lynx = new MenuItem ("lynx");
	item_mosaic = new MenuItem ("mosaic");
	item_mmm = new MenuItem ("mmm");
	item_lynx.setEnabled (false);
	item_mosaic.setEnabled (false);
	item_mmm.setEnabled (false);

	browser_select_menu.add (item_netscape);
	browser_select_menu.add (item_lynx);
	browser_select_menu.add (item_mosaic);
	browser_select_menu.add (item_mmm);

	help_menu = new Menu (namazuResources.getString ("HELP"));
	mbar.add (help_menu);
	mbar.setHelpMenu (help_menu);
	version_info = new MenuItem (namazuResources.getString ("VersionInfo"));
	version_info.addActionListener (this);
	help_menu.add (version_info);

	key_input_label = new Label (namazuResources.getString ("Keyword"));
	key_input_label.setAlignment (Label.LEFT);
	key_input = new TextField (20);
	key_input.addKeyListener (this);

	dir_label = new Label (namazuResources.getString ("IndexDirectory"));
	dir_input = new TextField (20);
	dir_input.addKeyListener (this);

	number_label = new Label (namazuResources.getString ("Number"));
	number_choice = new Choice ();
	number_choice.addItem ("10");
	number_choice.addItem ("20");
	number_choice.addItem ("30");
	number_choice.addItem ("50");
	number_choice.addItem ("100");
	number_choice.addItemListener (this);

	summary_label = new Label (namazuResources.getString ("Summary"));
	summary_choice = new Choice ();
	summary_choice.addItem (namazuResources.getString ("ON"));
	summary_choice.addItem (namazuResources.getString ("OFF"));
	summary_choice.addItemListener (this);

	format_label = new Label (namazuResources.getString ("Format"));
	format_choice = new Choice ();
	format_choice.addItem (namazuResources.getString ("TEXT"));
	format_choice.addItem (namazuResources.getString ("HTML"));
	format_choice.addItemListener (this);

	sort_label = new Label (namazuResources.getString ("Sort"));
	sort_choice = new Choice ();
	sort_choice.addItem (namazuResources.getString ("Increment"));
	sort_choice.addItem (namazuResources.getString ("Decrement"));
	sort_choice.addItemListener (this);

	b_ok = new Button (namazuResources.getString ("Start"));
	b_clear = new Button (namazuResources.getString ("Clear"));
	b_ok.addActionListener (this);
	b_clear.addActionListener (this);

	output = new TextArea (40, 30);
	output.setEditable (false);
	output.setBackground (Color.white);

	//default
	key_buf = new String ();
	number_buf = new String ("20");
	summary_buf = new String (namazuResources.getString ("ON"));

	p0 = new Panel ();
	p0.setLayout (new GridLayout (3, 1));

	p1 = new Panel ();
	p1.setLayout (new GridLayout (1, 2));
	p1.add (key_input_label);
	p1.add (key_input);

	p2 = new Panel ();
	p2.setLayout (new GridLayout (1, 2));
	p2.add (dir_label);
	p2.add (dir_input);

	p3 = new Panel ();
	p3.setLayout (new FlowLayout ());
	p3.add (number_label);
	p3.add (number_choice);
	p3.add (summary_label);
	p3.add (summary_choice);
	p3.add (format_label);
	p3.add (format_choice);
	p3.add (sort_label);
	p3.add (sort_choice);

	p0.add (p1);
	p0.add (p2);
	p0.add (p3);

	p4 = new Panel ();
	p4.setLayout (new FlowLayout ());
	p4.add (b_ok);
	p4.add (b_clear);

	setLayout (new BorderLayout ());
	add ("North", p0);
	add ("Center", p4);
	add ("South", output);

	setTitle (namazuResources.getString ("Namazu"));
	namazuhist_window = new NamazuHistory ();
	namazuhist_window.init ();
	namazuhist_window.settf (key_input);
  }

  public void keyPressed (KeyEvent ke) {
	if (ke.getKeyCode () == KeyEvent.VK_ENTER) {
	  goNamazu ();
	} else if (ke.isControlDown () == true) {
	  TextComponent tc = (TextComponent)ke.getComponent ();
	  ke.consume ();
	  switch (ke.getKeyCode ()) {
	  case KeyEvent.VK_A:
		tc.setCaretPosition (0);
		break;
	  case KeyEvent.VK_B:
		try {
		  tc.setCaretPosition (tc.getCaretPosition () - 1);
		  break;
		} catch (IllegalArgumentException iae) {
		  break;
		}
	  case KeyEvent.VK_D:
		now_cur = tc.getCaretPosition ();
		try {
		  tc.setText (
			  tc.getText ().substring (0, tc.getCaretPosition ()) +
			  tc.getText ().substring (tc.getCaretPosition () + 1,
									   tc.getText ().length ()));
		  tc.setCaretPosition (now_cur);
		  break;
		} catch (IllegalArgumentException iae) {
		  break;
		} catch (StringIndexOutOfBoundsException sioobe) {
		  break;
		}
	  case KeyEvent.VK_E:
		tc.setCaretPosition (tc.getText ().length ());
		break;
	  case KeyEvent.VK_F:
		tc.setCaretPosition (tc.getCaretPosition () + 1);
		break;
	  case KeyEvent.VK_K:
		  tc.setText (tc.getText ().substring (0, tc.getCaretPosition ()));
		/*
		 * 反転するの。
		tc.select (0, tc.getCaretPosition ());
		tc.setText (tc.getSelectedText ());
		*/
		break;
	  case KeyEvent.VK_W:
		now_cur = tc.getCaretPosition ();
		int bp = Math.min (cspace, now_cur);
		int ap = Math.max (cspace, now_cur);

		paste_buf = tc.getText ().substring (bp, ap);
		before = tc.getText ().substring (0, bp);
		after  = tc.getText ().substring (ap, tc.getText ().length ());
		tc.setText (before + after);
		tc.setCaretPosition (bp); // カーソル位置の調整
		break;
	  case KeyEvent.VK_Y:
		now_cur = tc.getCaretPosition ();
		String s = tc.getText ();
		before = s.substring (0, now_cur);
		after = s.substring (now_cur, s.length ());
		tc.setText (before + paste_buf + after);
		tc.setCaretPosition (now_cur + paste_buf.length ());
		// カーソル位置の調整
		break;
	  case KeyEvent.VK_U:
		tc.setText ("");
		break;
	  case KeyEvent.VK_SPACE:
		cspace = tc.getCaretPosition ();
		break;
	  }
	}
  }
  public void keyTyped (KeyEvent ke) {}
  public void keyReleased (KeyEvent ke) {}

  public void itemStateChanged (ItemEvent ie) {
	if (ie.getItemSelectable () == number_choice) {
	  number_buf = number_choice.getSelectedItem ();
	} else if (ie.getItemSelectable () == summary_choice) {
	  summary_buf = summary_choice.getSelectedItem ();
	} else if (ie.getItemSelectable () == sort_choice) {
	  sort_buf = sort_choice.getSelectedItem ();
	}
  }
  public void actionPerformed (ActionEvent ae) {
	String str;
	BufferedReader br;
	if (ae.getSource () == b_ok) {
	  goNamazu ();
	} else if (ae.getSource () == b_clear) {
	  key_input.setText ("");
	  dir_input.setText ("");
	  number_choice.select (0);
	  summary_choice.select (0);
	  format_choice.select (0);
	  sort_choice.select (0);
	  output.setText ("");
	} else if (ae.getSource () == edit_conf) {
	  if (first_conf == true) {
		first_conf = false;
		NamazuConf namazuconf_window = new NamazuConf ();
		namazuconf_window.init ();
		namazuconf_window.pack ();
		namazuconf_window.show ();
	  } else {
		return;
	  }

	} else if (ae.getSource () == view_usage) {
	  br = runCMD (NAMAZU_CMD, "-v", false);
	  try {
		while ((str = br.readLine ()) != null) {
		  output.append (str + lf);
		}
	  } catch (IOException ioe) {
		System.out.println (ioe.toString ());
	  }
	} else if (ae.getSource () == view_conf) {
	  br = runCMD (NAMAZU_CMD, "-C", true);
	  try {
		while ((str = br.readLine ()) != null) {
		  output.append (str + lf);
		}
	  } catch (IOException ioe) {
		System.out.println (ioe.toString ());
	  }
	} else if (ae.getSource () == view_hist) {
	  if (first_hist == false) {
		first_hist = true;
		NamazuHistory namazuhist_window = new NamazuHistory ();
		namazuhist_window.init ();
		namazuhist_window.settf (key_input);
		namazuhist_window.pack ();
		namazuhist_window.show ();
	  } else {
		namazuhist_window.settf (key_input);
		namazuhist_window.pack ();
		namazuhist_window.show ();
		return;
	  }

	} else if (ae.getSource () == browser_select_menu) {
	  //	  System.out.println ("SELECTED");

	} else if (ae.getSource () == version_info) {
	  NamazuInfo namazuinfo_window = new NamazuInfo (this);
	  /* changed Jul.10.1998 */
	  //	  namazuinfo_window.setMessage ("0.3", "Mar.17.1998");
	  namazuinfo_window.setMessage ("0.3.1", "Jul.10.1998");

	} else if (ae.getSource () == file_save) {
	  String newname = getfilename (false);
	  if (newname != null) {
		savefile (newname);
		filename = newname;
	  }
	} else if (ae.getSource () == file_quit) {
	  File f = new File (result_html);
	  f.delete ();
	  System.exit (0);
	}
  }

  public static void main (String args []) {
	Namazu namazu_window = new Namazu ();
	namazu_window.init ();
	namazu_window.pack ();
	namazu_window.show ();
  }

  public boolean isaliveNetscape () {
	File netscape_dir = new File (System.getProperty ("user.home", ""),
								  ".netscape");
	String [] netscape_files = netscape_dir.list ();
	for (int i=0; i<=netscape_files.length - 1; i++) {
	  if (netscape_files [i].equals ("lock")) {
		return true;
	  }
	}
	return false;
  }

  /* なんでこれで駄目やねん？シンボリックリンクには無効なん？
  public boolean isaliveNetscape () {
	File netscape_lockfile = new File (System.getProperty ("user.home", ""),
									   ".netscape/lock");
	if (netscape_lockfile.isFile () == true) {
	  System.out.println ("EXIST");
	  return true;
	} else {
	  System.out.println ("NOT EXIST");
	  return false;
	}
  }
  */
  public void goNamazu () {
	String str;
	BufferedReader br;
	cmd_option = getNamazuParm ();
	if (cmd_option == null) {
	  return;
	}
	namazuhist_window.addhistory (key_input.getText ());
	br = runCMD (NAMAZU_CMD, cmd_option, true);
	if (namazuResources.getString ("TEXT").equals (format_buf)) {
	  try {
		while ((str = br.readLine ()) != null) {
		  output.append (str + lf);
		}
	  } catch (IOException ioe) {
		System.out.println (ioe.toString ());
	  }
	} else {
	  try {
		FileWriter writer = new FileWriter (result_html);
		while ((str = br.readLine ()) != null) {
		  writer.write (str + lf, 0, (str + lf).length ());
		}
		writer.close ();
	  } catch (IOException ioe) {
		System.out.println (ioe.toString ());
	  }
	  if (isaliveNetscape ()) {
		netscape_options = "-remote openURL(file://" + result_html + ")";
	  } else {
		netscape_options = "file://" + result_html;
	  }
	  runCMD (NETSCAPE_CMD, netscape_options, true);
	}
  }

  public String getNamazuParm () {
	String namazu_option = new String ("");
	dir_buf = dir_input.getText ();
	if ("".equals (dir_buf)) {
	  dir_buf = ".";
	}
	key_buf = key_input.getText ();
	if ("".equals (key_buf)) {
	  output.setText (namazuResources.getString ("Keyword missing"));
	  return null;
	}
	number_buf = number_choice.getSelectedItem ();
	summary_buf = summary_choice.getSelectedItem ();
	if (namazuResources.getString ("OFF").equals (summary_buf)) {
	  namazu_option += "-s ";
	}
	format_buf = format_choice.getSelectedItem ();
	if (namazuResources.getString ("HTML").equals (format_buf)) {
	  namazu_option += "-h ";
	}
	sort_buf = sort_choice.getSelectedItem ();
	if (namazuResources.getString ("Decrement").equals (sort_buf)) {
	  namazu_option += "-e ";
	}
	/* changed Jul.10.1998
	namazu_option = namazu_option + "-n " + number_buf + " " +
	             dir_buf + " " + key_buf;
	 */
	namazu_option = namazu_option + "-n " + number_buf + " " +
	             key_buf + " " + dir_buf;
	/* end Jul.10.1998 */

	return namazu_option;
  }	

  private BufferedReader runCMD (String cmd, String cmd_option, boolean b) {
	//	if (Locale.getDefault () == Locale.JAPANESE) {
	//	  System.out.println ("にほん");
	//	}
	String namazu_cmd = NAMAZU_CMD;
	String netscape_cmd = NETSCAPE_CMD;
	String str;
	BufferedReader br;

	if (cmd == NAMAZU_CMD) {
	  String cmd_option_default = "-a";
	  /* add Jul.10.1998 */
	  if (Locale.getDefault ().equals (Locale.JAPANESE)) {
		cmd_option_default += J;
	  } else {
		cmd_option_default += E;
	  }
	  /* end Jul.10.1998 */
	  namazu_cmd = namazu_cmd + " " + cmd_option_default + " " + cmd_option;
	  try {
		Process proc = Runtime.getRuntime ().exec (namazu_cmd);
		proc.waitFor ();
		if (b == true) {
		  br = new BufferedReader (new InputStreamReader
								   ((proc.getInputStream ())));
		} else {
		  br = new BufferedReader (new InputStreamReader
								   ((proc.getErrorStream ())));
		}
		return br;
	  } catch (IOException ioe) {
		System.out.println (ioe.toString ());
	  } catch (InterruptedException ie) {
		System.out.println (ie.toString ());
	  }
	} else if (cmd == NETSCAPE_CMD) {
	  cmd = cmd + " " + cmd_option;
	  try {
		Process proc = Runtime.getRuntime ().exec (cmd);
		proc.waitFor ();
		br = new BufferedReader (new InputStreamReader
								 ((proc.getInputStream ())));
		return br;
	  } catch (IOException ioe) {
		System.out.println (ioe.toString ());
	  } catch (InterruptedException ie) {
		System.out.println (ie.toString ());
	  }
	}
	return null; // never reached
  }

  private String getfilename (boolean isOpen) {
	FileDialog dialog =
	  new FileDialog (this,
					  isOpen ? namazuResources.getString ("Open"):
					           namazuResources.getString ("Save"),
					  isOpen ? FileDialog.LOAD : FileDialog.SAVE);
		dialog.show ();

		if (dialog.getDirectory () != null && dialog.getFile () != null)
		  return dialog.getDirectory () + dialog.getFile ();
		else
		  return null;
  }
  private void savefile (String filename) {
	FileWriter writer;
	try {
	  writer = new FileWriter (filename);
	} catch (IOException ioe) {
	  System.err.println (ioe.toString ());
	  return;
	}
	String text = output.getText ();
	try	{
	  writer.write (text, 0, text.length ());
	  writer.close ();
	} catch (IOException ioe) {
	  System.out.println (ioe.toString());
	}
  }
}
/**
 * @author      まつむらのぞみ
 * @version     0.3.1, Jul/10/1998
 * @since       JDK1.1.5
 * Done Memo    キーワードとインデックスの指定の順序が逆になったことの対応。
 *              Locale に従い、namazu の呼び出し時に、-L {JAPANESE|ENGLISH}
 *              を付けるようにした。
 */
