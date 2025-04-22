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

# Stored procedures 
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

# Views 
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
        master.title("✈ Flight Tracker Interface")
        master.geometry('800x600')
        master.configure(bg='#E0F7FA') 

        style = ttk.Style(master)
        style.theme_use('clam')
        style.configure('Header.TLabel', font=('Helvetica', 20, 'bold'), background='#0288D1', foreground='white')
        style.configure('Section.TLabel', font=('Helvetica', 12), background='#E0F7FA')
        style.configure('Flight.TButton', font=('Helvetica', 10, 'bold'), background='#0288D1', foreground='white')
        style.map('Flight.TButton', background=[('active', '#0277BD')])
        style.configure('TCombobox', fieldbackground='white')
        style.configure('TLabel', background='#E0F7FA')
        style.configure('Treeview', rowheight=25)
        style.configure('Treeview.Heading', font=('Helvetica', 10, 'bold'))

        header = tk.Frame(master, bg='#0288D1', height=50)
        header.pack(fill='x')
        ttk.Label(header, text='✈ Flight Tracker', style='Header.TLabel').pack(pady=10)

        select_frame = tk.Frame(master, bg='#E0F7FA')
        select_frame.pack(fill='x', padx=20, pady=(10, 0))
        ttk.Label(select_frame, text='Select Procedure/View:', style='Section.TLabel').grid(row=0, column=0, sticky='w')
        self.selection = tk.StringVar()
        self.combo = ttk.Combobox(select_frame, textvariable=self.selection,
                                  values=list(procedures.keys()) + list(views.keys()), state='readonly')
        self.combo.grid(row=0, column=1, sticky='we', padx=5)
        self.combo.bind('<<ComboboxSelected>>', self.build_params)
        select_frame.columnconfigure(1, weight=1)

        self.params_frame = tk.LabelFrame(master, text='Parameters', bg='#E0F7FA')
        self.params_frame.pack(fill='x', padx=20, pady=10)
        self.entries = []

        ttk.Button(master, text='Run', style='Flight.TButton', command=self.run).pack(pady=5)

        result_frame = tk.Frame(master, bg='#E0F7FA')
        result_frame.pack(fill='both', expand=True, padx=20, pady=10)
        self.tree = ttk.Treeview(result_frame, show='headings')
        self.tree.pack(fill='both', expand=True)

    def build_params(self, event):
        for child in self.params_frame.winfo_children():
            child.destroy()
        self.entries.clear()
        key = self.selection.get()
        param_list = procedures.get(key, [])
        if not param_list:
            ttk.Label(self.params_frame, text='(No parameters)', style='Section.TLabel').pack(anchor='w')
            return
        for name, typ in param_list:
            row = tk.Frame(self.params_frame, bg='#E0F7FA')
            row.pack(fill='x', pady=2)
            ttk.Label(row, text=f'{name} ({typ}):', style='Section.TLabel').pack(side='left')
            ent = tk.Entry(row, width=30)
            ent.pack(side='left', padx=5)
            self.entries.append((name, typ, ent))

    def run(self):
        key = self.selection.get()
        if not key:
            messagebox.showerror('Error', 'Select an item first.')
            return
        args = []
        for name, typ, ent in self.entries:
            val = ent.get().strip()
            if not val and name in null_parameters.get(key, []):
                args.append(None)
                continue
            elif not val:
                messagebox.showerror('Error', f'{name} required.')
                return
            if typ == 'int':
                try:
                    val = int(val)
                except ValueError:
                    messagebox.showerror('Error', f'{name} must be int.')
                    return
            args.append(val)
        try:
            conn = get_connection()
            cur = conn.cursor()
            if key in procedures:
                placeholders = ','.join(['%s'] * len(args))
                cur.execute(f'CALL {key}({placeholders})', tuple(args))
                conn.commit()
                messagebox.showinfo('Done', f'Procedure {key} executed.')
                for item in self.tree.get_children():
                    self.tree.delete(item)
                self.tree['columns'] = []
            else:
                cur.execute(f'SELECT * FROM {key}')
                rows = cur.fetchall()
                cols = [desc[0] for desc in cur.description]
                for item in self.tree.get_children():
                    self.tree.delete(item)
                self.tree['columns'] = cols
                for c in cols:
                    self.tree.heading(c, text=c)
                    self.tree.column(c, stretch=True)
                for r in rows:
                    self.tree.insert('', 'end', values=r)
        except mysql.connector.Error as err:
            messagebox.showerror('DB Error', str(err))
        finally:
            if 'cur' in locals(): cur.close()
            if 'conn' in locals(): conn.close()

if __name__ == '__main__':
    root = tk.Tk()
    app = ProcedureRunnerApp(root)
    root.mainloop()
