import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;

public class NamazuConf extends Frame implements ActionListener {

  MenuBar mbar_conf;
  Menu file_conf_menu, edit_conf_menu;
  MenuItem file_conf_open, file_conf_save, file_conf_quit;
  MenuItem edit_conf_now_load, edit_conf_default_load, edit_conf_clear;
  Panel pc1, pc2, pc3;

  final static private String INDEX_DEFALUT = "/usr/local/namazu/index";
  final static private String REPLACE_FROM_DEFALUT = "/home/foo/public_html/";
  final static private String REPLACE_TO_DEFALUT = "http://www.hoge.jp/%7Efoo/g";
  final static private String BASE_DEFAULT = "file://localhost/home/foo/documents/";
  final static private String WAKACHI_DEFAULT = "/usr/local/bin/kakasi";
  final static private String TMP_DEFAULT = "/tmp";
  final static private String LOGGING_DEFAULT = "OFF";
  final static private String CONF_FILENAME_DEFAULT = "/usr/local/namazu/lib/namazu.conf";

  final static private String INDEX_TAG = "INDEX";
  final static private String REPLACE_TAG = "REPLACE";
  final static private String BASE_TAG = "BASE";
  final static private String WAKACHI_TAG = "WAKACHI";
  final static private String TMP_TAG = "TMP";
  final static private String LOGGING_TAG = "LOGGING";

  TextField conf_filename_tf, index_tf, replace_from_tf, replace_to_tf;
  TextField base_tf, wakachi_tf, tmp_tf, logging_tf;

  public boolean isOpenwindow;

  ResourceBundle namazuResources =
    ResourceBundle.getBundle ("NamazuResources");

  String lf = System.getProperty ("line.separator", "");
  static String conf_filename = null;

  public void init () {
	mbar_conf = new MenuBar ();
	setMenuBar (mbar_conf);

	file_conf_menu = new Menu (namazuResources.getString ("FILE"));
	mbar_conf.add (file_conf_menu);
	file_conf_open = new MenuItem (namazuResources.getString ("Open"));
	file_conf_save = new MenuItem (namazuResources.getString ("Save"));
	file_conf_quit = new MenuItem (namazuResources.getString ("Quit"));
	file_conf_open.addActionListener (this);
	file_conf_save.addActionListener (this);
	file_conf_quit.addActionListener (this);
	file_conf_menu.add (file_conf_open);
	file_conf_menu.add (file_conf_save);
	file_conf_menu.add (file_conf_quit);

	edit_conf_menu = new Menu (namazuResources.getString ("EDIT"));
	mbar_conf.add (edit_conf_menu);
	edit_conf_now_load = new MenuItem (namazuResources.getString ("Load Now"));
	edit_conf_default_load = new MenuItem
	  (namazuResources.getString ("Load System Default"));
	edit_conf_clear = new MenuItem (namazuResources.getString ("All Clear"));
	edit_conf_now_load.addActionListener (this);
	edit_conf_default_load.addActionListener (this);
	edit_conf_clear.addActionListener (this);
	edit_conf_menu.add (edit_conf_now_load);
	edit_conf_menu.add (edit_conf_default_load);
	edit_conf_menu.add (edit_conf_clear);

	pc1 = new Panel ();
	pc1.setLayout (new FlowLayout ());
	pc1.add (new Label (namazuResources.getString ("Configuration File")));
	pc1.add (conf_filename_tf = new TextField (30));

	pc2 = new Panel ();
	pc2.setLayout (new GridLayout (7, 1));
	pc2.add (new Label (namazuResources.getString ("Index Directory")));
	pc2.add (new Label (namazuResources.getString ("Replacement (From)")));
	pc2.add (new Label (namazuResources.getString ("Replacement (To)")));
	pc2.add (new Label (namazuResources.getString ("BASE HREF")));
	pc2.add (new Label (namazuResources.getString ("WAKACHI")));
	pc2.add (new Label (namazuResources.getString ("Temp Directory")));
	pc2.add (new Label (namazuResources.getString ("Logging")));

	pc3 = new Panel ();
	pc3.setLayout (new GridLayout (7, 1));
	pc3.add (index_tf = new TextField (40));
	pc3.add (replace_from_tf = new TextField (40));
	pc3.add (replace_to_tf = new TextField (40));
	pc3.add (base_tf = new TextField (40));
	pc3.add (wakachi_tf = new TextField (40));
	pc3.add (tmp_tf = new TextField (40));
	pc3.add (logging_tf = new TextField (40));

	setLayout (new BorderLayout ());
	add ("North", pc1);
	add ("West", pc2);
	add ("East", pc3);
	setTitle (namazuResources.getString ("Namazu Configuration"));
  }
  public void actionPerformed (ActionEvent ae) {
	String index, replace, replace_from, replace_to;
	String base, wakachi, tmp, logging;
	String conf_str;
	conf_filename = conf_filename_tf.getText ();
	if ("".equals (conf_filename)) {
	  conf_filename = CONF_FILENAME_DEFAULT;
	}
	if (ae.getSource () == file_conf_open) {
	  FileDialog conf_dialog =
		new FileDialog (this, namazuResources.getString ("Open"));
	  conf_dialog.setDirectory ("/usr/local/namazu/lib");
	  conf_dialog.setFile ("*.conf");
	  conf_dialog.show ();
	  if (conf_dialog.getDirectory () != null &&
		  conf_dialog.getFile () != null) {
		conf_filename = conf_dialog.getDirectory () + conf_dialog.getFile ();
		conf_filename_tf.setText (conf_filename);
	  }
	} else if (ae.getSource () == file_conf_save) {
	  index = index_tf.getText ();
	  replace_from = replace_from_tf.getText ();
	  replace_to = replace_to_tf.getText ();
	  base = base_tf.getText ();
	  wakachi = wakachi_tf.getText ();
	  tmp = tmp_tf.getText ();
	  logging = logging_tf.getText ();

	  if ("".equals (index)) {
		index = INDEX_DEFALUT;
	  }
	  if ("".equals (replace_from)) {
		replace_from = REPLACE_FROM_DEFALUT;
	  }
	  if ("".equals (replace_to)) {
		replace_to = REPLACE_TO_DEFALUT;
	  }
	  if ("".equals (base)) {
		base = BASE_DEFAULT;
	  }
	  if ("".equals (wakachi)) {
		wakachi = WAKACHI_DEFAULT;
	  }
	  if ("".equals (tmp)) {
		tmp = TMP_DEFAULT;
	  }
	  if ("".equals (logging)) {
		logging = LOGGING_DEFAULT;
	  }
	  index = INDEX_TAG + "\t" + index + lf;
	  replace = REPLACE_TAG + "\t" + replace_from + "\t" + replace_to + lf;
	  base = BASE_TAG + "\t" + base + lf;
	  wakachi = WAKACHI_TAG + "\t" + wakachi + lf;
	  tmp = TMP_TAG + "\t" + tmp + lf;
	  logging = LOGGING_TAG + "\t" + logging + lf;
	  conf_str = index + replace + base + wakachi + tmp + logging;

	  FileWriter conf_writer;
	  try {
	  conf_writer = new FileWriter (conf_filename);
	  conf_writer.write (conf_str, 0, conf_str.length ());
	  conf_writer.close ();
	  } catch (IOException ioe) {
		System.err.println (ioe.toString ());
	  }

	} else if (ae.getSource () == file_conf_quit) {
	  Namazu.first_conf = true;
	  setVisible (false);
	  //	  dispose ();
	  return;

	} else if (ae.getSource () == edit_conf_now_load) {
	  clearconfWindow ();
	  conf_filename_tf.setText (conf_filename);
	  BufferedReader conf_reader;
	  String token = "\t";
	  try {
		conf_reader = new BufferedReader (new InputStreamReader (
									 new FileInputStream (conf_filename)));
		while ((conf_str = conf_reader.readLine ()) != null) {
		  if (!conf_str.startsWith ("#")) {
			StringTokenizer st = new StringTokenizer (conf_str, token);
			int element_number = st.countTokens ();
			String [] element_list = new String [element_number];
			for (int i=0; i<element_number; i++) {
			  element_list [i] = st.nextToken ();
			}
			for (int j=0; j<element_number; j++) {
			  if (INDEX_TAG.equals (element_list [j])) {
				index_tf.setText (element_list [j+1]);
			  } else if (REPLACE_TAG.equals (element_list [j])) {
				replace_from_tf.setText (element_list [j+1]);
				replace_to_tf.setText (element_list [j+2]);
			  } else if (BASE_TAG.equals (element_list [j])) {
				base_tf.setText (element_list [j+1]);
			  } else if (WAKACHI_TAG.equals (element_list [j])) {
				wakachi_tf.setText (element_list [j+1]);
			  } else if (TMP_TAG.equals (element_list [j])) {
				tmp_tf.setText (element_list [j+1]);
			  } else if (LOGGING_TAG.equals (element_list [j])) {
				logging_tf.setText (element_list [j+1]);
			  }
			}
		  }
		}
	  } catch (NoSuchElementException nsee) {
		System.out.println (nsee.toString ());
	  } catch (StringIndexOutOfBoundsException sioobe) {
		System.out.println (sioobe.toString ());
	  } catch (FileNotFoundException fnfe) {
		System.out.println (fnfe.toString ());
	  } catch (IOException ioe) {
		System.err.println (ioe.toString ());
	  }

	} else if (ae.getSource () == edit_conf_default_load) {
	  index_tf.setText (INDEX_DEFALUT);
	  replace_from_tf.setText (REPLACE_FROM_DEFALUT);
	  replace_to_tf.setText (REPLACE_TO_DEFALUT);
	  base_tf.setText (BASE_DEFAULT);
	  wakachi_tf.setText (WAKACHI_DEFAULT);
	  tmp_tf.setText (TMP_DEFAULT);
	  logging_tf.setText (LOGGING_DEFAULT);
	} else if (ae.getSource () == edit_conf_clear) {
	  clearconfWindow ();
	}
  }

  public static void main (String args []) {
  NamazuConf namazuconf_window = new NamazuConf ();
  namazuconf_window.init ();
  namazuconf_window.pack ();
  namazuconf_window.show ();
  }
  private void clearconfWindow () {
	index_tf.setText ("");
	replace_from_tf.setText ("");
	replace_to_tf.setText ("");
	base_tf.setText ("");
	wakachi_tf.setText ("");
	tmp_tf.setText ("");
	logging_tf.setText ("");
  }
}
