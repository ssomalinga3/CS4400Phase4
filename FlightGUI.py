import tkinter as tk
from tkinter import ttk, messagebox
import mysql.connector
from datetime import datetime

# Database connection parameters - change to reflect your user system
DB_HOST = 'localhost'
DB_USER = 'root'
DB_PASSWORD = 'password'
DB_NAME = 'flight_tracking'

# Connect to the database
def get_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )

# Stored procedures for Flight Tracking system
procedures = {
    "add_airplane": [
        ("ip_airlineID", "str"),
        ("ip_tail_num", "str"),
        ("ip_seat_capacity", "int"),
        ("ip_speed", "int"),
        ("ip_locationID", "str"),
        ("ip_plane_type", "str"),
        ("ip_maintenanced", "str"),
        ("ip_model", "str"),
        ("ip_neo", "str")
    ],
    "add_airport": [
        ("ip_airportID", "str"),
        ("ip_airport_name", "str"),
        ("ip_city", "str"),
        ("ip_state", "str"),
        ("ip_country", "str"),
        ("ip_locationID", "str")
    ],
    "add_person": [
        ("ip_personID", "str"),
        ("ip_first_name", "str"),
        ("ip_last_name", "str"),
        ("ip_locationID", "str"),
        ("ip_taxID", "str"),
        ("ip_experience", "int"),
        ("ip_miles", "int"),
        ("ip_funds", "int")
    ],
    "grant_or_revoke_pilot_license": [
        ("ip_personID", "str"),
        ("ip_license", "str")
    ],
    "offer_flight": [
        ("ip_flightID", "str"),
        ("ip_routeID", "str"),
        ("ip_support_airline", "str"),
        ("ip_support_tail", "str"),
        ("ip_progress", "int"),
        ("ip_next_time", "str"),
        ("ip_cost", "int")
    ],
    "flight_landing": [("ip_flightID", "str")],
    "flight_takeoff": [("ip_flightID", "str")],
    "passengers_board": [("ip_flightID", "str")],
    "passengers_disembark": [("ip_flightID", "str")],
    "assign_pilot": [
        ("ip_flightID", "str"),
        ("ip_personID", "str")
    ],
    "recycle_crew": [("ip_flightID", "str")],
    "retire_flight": [("ip_flightID", "str")],
    "simulation_cycle": []
}

# Views for Flight Tracking system
views = {
    "flights_in_the_air": [],
    "flights_on_the_ground": [],
    "people_in_the_air": [],
    "people_on_the_ground": [],
    "route_summary": [],
    "alternative_airports": []
}


# Need to add parameters that can be null/empty 

null_parameters = {
    "add_airplane": [
        ("ip_airlineID"),
        ("ip_tail_num"),
        ("ip_seat_capacity"),
        ("ip_speed"),
        ("ip_locationID"),
        ("ip_plane_type"),
        ("ip_maintenanced"),
        ("ip_model"),
        ("ip_neo")
    ],
    "add_airport": [
        ("ip_airportID"),
        ("ip_airport_name"),
        ("ip_city"),
        ("ip_state"),
        ("ip_country"),
        ("ip_locationID")
    ],
    "add_person": [
        ("ip_personID"),
        ("ip_first_name"),
        ("ip_last_name"),
        ("ip_locationID"),
        ("ip_taxID"),
        ("ip_experience"),
        ("ip_miles"),
        ("ip_funds")
    ],
    "grant_or_revoke_pilot_license": [
        ("ip_personID"),
        ("ip_license")
    ],
    "offer_flight": [
        ("ip_flightID"),
        ("ip_routeID"),
        ("ip_support_airline"),
        ("ip_support_tail"),
        ("ip_progress"),
        ("ip_next_time"),
        ("ip_cost")
    ],
    "flight_landing": [("ip_flightID")],
    "flight_takeoff": [("ip_flightID")],
    "passengers_board": [("ip_flightID")],
    "passengers_disembark": [("ip_flightID")],
    "assign_pilot": [
        ("ip_flightID"),
        ("ip_personID")
    ],
    "recycle_crew": [("ip_flightID")],
    "retire_flight": [("ip_flightID")],
    "simulation_cycle": []
}

class ProcedureRunnerApp:
    def __init__(self, master):
        self.master = master
        master.title("Flight Tracking Interface")

        tk.Label(master, text="Select Procedure/View:").grid(row=0, column=0, padx=5, pady=5, sticky='e')
        self.selection = tk.StringVar()
        self.combo = ttk.Combobox(
            master,
            textvariable=self.selection,
            values=list(procedures.keys()) + list(views.keys()),
            state='readonly'
        )
        self.combo.grid(row=0, column=1, padx=5, pady=5, sticky='w')
        self.combo.bind("<<ComboboxSelected>>", self.build_params)

        self.params_frame = tk.Frame(master)
        self.params_frame.grid(row=1, column=0, columnspan=2, padx=5, pady=5, sticky='w')
        self.entries = []

        tk.Button(master, text="Run", command=self.run).grid(
            row=2, column=0, columnspan=2, padx=5, pady=5)

    def build_params(self, event):
        for w in self.params_frame.winfo_children():
            w.destroy()
        self.entries.clear()
        key = self.selection.get()
        param_list = procedures.get(key, [])
        for name, typ in param_list:
            frm = tk.Frame(self.params_frame)
            frm.pack(anchor='w', pady=2)
            tk.Label(frm, text=f"{name} ({typ}):").pack(side='left')
            ent = tk.Entry(frm, width=50)
            ent.pack(side='left')
            self.entries.append((name, typ, ent))
        if not param_list:
            tk.Label(self.params_frame, text="(No parameters)").pack(anchor='w')

    def run(self):
        key = self.selection.get()
        if not key:
            messagebox.showerror("Error", "Select an item first.")
            return
        args = []
        for name, typ, ent in self.entries:
            v = ent.get().strip()
            if not v and name in null_parameters.get(key):
                args.append(None)
                continue
            elif not v:
                messagebox.showerror("Error", f"{name} required.")
                return
            elif typ == 'int':
                try:
                    v = int(v)
                except ValueError:
                    messagebox.showerror("Error", f"{name} must be int.")
                    return
            args.append(v)
        try:
            conn = get_connection()
            cur = conn.cursor()
            if key in procedures:
                placeholders = ",".join(["%s"] * len(args))
                cur.execute(f"CALL {key}({placeholders})", tuple(args))
                conn.commit()
                messagebox.showinfo("Done", f"Procedure {key} executed.")
            else:
                cur.execute(f"SELECT * FROM {key}")
                rows = cur.fetchall()
                cols = [d[0] for d in cur.description]
                dlg = tk.Toplevel(self.master)
                dlg.title(key)
                tv = ttk.Treeview(dlg, columns=cols, show='headings')
                for c in cols:
                    tv.heading(c, text=c)
                    tv.column(c, width=100)
                for r in rows:
                    tv.insert('', 'end', values=r)
                tv.pack(fill='both', expand=True)
        except mysql.connector.Error as e:
            messagebox.showerror("DB Error", str(e))
        finally:
            cur.close()
            conn.close()

if __name__ == '__main__':
    root = tk.Tk()
    ProcedureRunnerApp(root)
    root.mainloop()
