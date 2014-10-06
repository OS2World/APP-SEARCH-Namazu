import java.awt.*;
import java.awt.event.*;
import java.util.*;

class NamazuInfo extends Dialog implements ActionListener {
  ResourceBundle namazuResources =
    ResourceBundle.getBundle ("NamazuResources");
  Label version_tag, version;
  Label lastupdate_tag, lastupdate;
  Button b_ok;

  public NamazuInfo (Frame parent) {
	//	super (parent, "VersionInfo", true);
	super (parent, true);
	setTitle (namazuResources.getString ("VersionInfo"));
	setLayout (new BorderLayout ());

	version_tag = new Label (namazuResources.getString ("VERSION"),
							 Label.CENTER);
	version = new Label ("", Label.CENTER);
	lastupdate_tag = new Label (namazuResources.getString ("LastUpdate"),
								Label.CENTER);
	lastupdate = new Label ("", Label.CENTER);

	b_ok = new Button ("OK");
	b_ok.addActionListener (this);

	Panel p0 = new Panel ();
	p0.setLayout (new GridLayout (2, 2));
	p0.add (version_tag);
	p0.add (version);
	p0.add (lastupdate_tag);
	p0.add (lastupdate);

	Label dummy = new Label ("");
	Panel p1 = new Panel ();
	p1.add (dummy);
	p1.add (b_ok);
	p1.add (dummy);

	add ("Center", p0);
	add ("South", p1);

  }
  public void actionPerformed (ActionEvent ae) {
	if (ae.getSource () == b_ok) {
	  setVisible (false);
	}
  }

  public void setMessage (String versionmsg, String lastupdatemsg) {
	version.setText (versionmsg);
	lastupdate.setText (lastupdatemsg);
	pack ();
	show ();
  }
}
