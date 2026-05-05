package com.studyplan.extension;

import com.google.appinventor.components.annotations.SimpleFunction;
import com.google.appinventor.components.annotations.SimpleProperty;
import com.google.appinventor.components.annotations.SimpleEvent;
import com.google.appinventor.components.runtime.AndroidNonvisibleComponent;
import com.google.appinventor.components.runtime.ComponentContainer;
import com.google.appinventor.components.runtime.EventDispatcher;
import com.google.appinventor.components.runtime.util.YailList;
import android.content.Context;
import android.content.SharedPreferences;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

public class StudyPlan extends AndroidNonvisibleComponent {

    private static final String PREFS_NAME = "StudyPlanData";
    private static final String KEY_TASKS = "tasks";
    private SharedPreferences prefs;
    private JSONArray tasksArray;
    private final SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault());

    public StudyPlan(ComponentContainer container) {
        super(container.$form());
        prefs = container.$context().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        loadTasks();
    }

    private void loadTasks() {
        String data = prefs.getString(KEY_TASKS, "[]");
        try {
            tasksArray = new JSONArray(data);
        } catch (JSONException e) {
            tasksArray = new JSONArray();
        }
    }

    private void saveTasks() {
        prefs.edit().putString(KEY_TASKS, tasksArray.toString()).apply();
    }

    @SimpleFunction(description = "Tambah tugas baru. Prioritas: high, medium, low. Return ID tugas.")
    public String TambahTugas(String judul, String mataPelajaran, String deskripsi,
                               String deadline, String prioritas) {
        try {
            String id = UUID.randomUUID().toString().substring(0, 8);
            JSONObject task = new JSONObject();
            task.put("id", id);
            task.put("judul", judul);
            task.put("mataPelajaran", mataPelajaran);
            task.put("deskripsi", deskripsi);
            task.put("deadline", deadline);
            task.put("prioritas", prioritas.toLowerCase());
            task.put("status", "pending");
            task.put("dibuatPada", dateFormat.format(new Date()));
            tasksArray.put(task);
            saveTasks();
            TugasDitambahkan(id, judul, mataPelajaran);
            return id;
        } catch (JSONException e) {
            return "";
        }
    }

    @SimpleFunction(description = "Edit tugas berdasarkan ID.")
    public boolean EditTugas(String id, String judul, String mataPelajaran,
                              String deskripsi, String deadline, String prioritas) {
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("id").equals(id)) {
                    task.put("judul", judul);
                    task.put("mataPelajaran", mataPelajaran);
                    task.put("deskripsi", deskripsi);
                    task.put("deadline", deadline);
                    task.put("prioritas", prioritas.toLowerCase());
                    saveTasks();
                    TugasDiperbarui(id, judul);
                    return true;
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return false;
    }

    @SimpleFunction(description = "Hapus tugas berdasarkan ID.")
    public boolean HapusTugas(String id) {
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("id").equals(id)) {
                    String judul = task.getString("judul");
                    tasksArray.remove(i);
                    saveTasks();
                    TugasDihapus(id, judul);
                    return true;
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return false;
    }

    @SimpleFunction(description = "Tandai tugas sebagai selesai.")
    public boolean TandaiSelesai(String id) {
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("id").equals(id)) {
                    task.put("status", "completed");
                    saveTasks();
                    TugasSelesai(id, task.getString("judul"));
                    return true;
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return false;
    }

    @SimpleFunction(description = "Tandai tugas sebagai belum selesai.")
    public boolean TandaiBelumSelesai(String id) {
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("id").equals(id)) {
                    task.put("status", "pending");
                    saveTasks();
                    return true;
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return false;
    }

    @SimpleFunction(description = "Ambil semua tugas dalam format JSON string.")
    public String AmbilSemuaTugas() {
        return tasksArray.toString();
    }

    @SimpleFunction(description = "Ambil tugas pending dalam format JSON string.")
    public String AmbilTugasPending() {
        return filterByStatus("pending").toString();
    }

    @SimpleFunction(description = "Ambil tugas selesai dalam format JSON string.")
    public String AmbilTugasSelesai() {
        return filterByStatus("completed").toString();
    }

    @SimpleFunction(description = "Ambil detail tugas berdasarkan ID.")
    public String AmbilDetailTugas(String id) {
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("id").equals(id)) {
                    return task.toString();
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return "";
    }

    @SimpleFunction(description = "Ambil tugas berdasarkan prioritas (high/medium/low).")
    public String AmbilTugasByPrioritas(String prioritas) {
        JSONArray result = new JSONArray();
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("prioritas").equalsIgnoreCase(prioritas)
                    && task.getString("status").equals("pending")) {
                    result.put(task);
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return result.toString();
    }

    @SimpleFunction(description = "Ambil tugas berdasarkan mata pelajaran.")
    public String AmbilTugasByMapel(String mataPelajaran) {
        JSONArray result = new JSONArray();
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("mataPelajaran").equalsIgnoreCase(mataPelajaran)) {
                    result.put(task);
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return result.toString();
    }

    @SimpleFunction(description = "Cari tugas berdasarkan kata kunci.")
    public String CariTugas(String keyword) {
        JSONArray result = new JSONArray();
        String kw = keyword.toLowerCase();
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                String judul = task.getString("judul").toLowerCase();
                String desc = task.optString("deskripsi", "").toLowerCase();
                if (judul.contains(kw) || desc.contains(kw)) {
                    result.put(task);
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return result.toString();
    }

    @SimpleFunction(description = "Hapus semua tugas yang sudah selesai.")
    public void HapusSemuaTugasSelesai() {
        JSONArray remaining = new JSONArray();
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("status").equals("pending")) {
                    remaining.put(task);
                }
            }
        } catch (JSONException e) { /* ignore */ }
        tasksArray = remaining;
        saveTasks();
    }

    @SimpleFunction(description = "Hapus SEMUA tugas (reset data).")
    public void HapusSemuaTugas() {
        tasksArray = new JSONArray();
        saveTasks();
    }

    @SimpleFunction(description = "Ambil daftar judul tugas pending sebagai list.")
    public YailList AmbilDaftarJudul() {
        List<String> titles = new ArrayList<>();
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("status").equals("pending")) {
                    titles.add(task.getString("judul"));
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return YailList.makeList(titles);
    }

    @SimpleFunction(description = "Ambil daftar ID tugas pending sebagai list.")
    public YailList AmbilDaftarId() {
        List<String> ids = new ArrayList<>();
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("status").equals("pending")) {
                    ids.add(task.getString("id"));
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return YailList.makeList(ids);
    }

    @SimpleProperty(description = "Total jumlah tugas.")
    public int TotalTugas() {
        return tasksArray.length();
    }

    @SimpleProperty(description = "Jumlah tugas belum selesai.")
    public int TugasBelumSelesai() {
        return filterByStatus("pending").length();
    }

    @SimpleProperty(description = "Jumlah tugas sudah selesai.")
    public int JumlahTugasSelesai() {
        return filterByStatus("completed").length();
    }

    @SimpleProperty(description = "Jumlah tugas urgent yang pending.")
    public int TugasUrgent() {
        int count = 0;
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("prioritas").equals("high")
                    && task.getString("status").equals("pending")) {
                    count++;
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return count;
    }

    @SimpleProperty(description = "Persentase progress tugas selesai (0-100).")
    public int ProgressPersen() {
        if (tasksArray.length() == 0) return 0;
        return (int) ((filterByStatus("completed").length() * 100.0) / tasksArray.length());
    }

    @SimpleEvent(description = "Dipanggil ketika tugas baru ditambahkan.")
    public void TugasDitambahkan(String id, String judul, String mataPelajaran) {
        EventDispatcher.dispatchEvent(this, "TugasDitambahkan", id, judul, mataPelajaran);
    }

    @SimpleEvent(description = "Dipanggil ketika tugas diperbarui.")
    public void TugasDiperbarui(String id, String judul) {
        EventDispatcher.dispatchEvent(this, "TugasDiperbarui", id, judul);
    }

    @SimpleEvent(description = "Dipanggil ketika tugas dihapus.")
    public void TugasDihapus(String id, String judul) {
        EventDispatcher.dispatchEvent(this, "TugasDihapus", id, judul);
    }

    @SimpleEvent(description = "Dipanggil ketika tugas ditandai selesai.")
    public void TugasSelesai(String id, String judul) {
        EventDispatcher.dispatchEvent(this, "TugasSelesai", id, judul);
    }

    private JSONArray filterByStatus(String status) {
        JSONArray result = new JSONArray();
        try {
            for (int i = 0; i < tasksArray.length(); i++) {
                JSONObject task = tasksArray.getJSONObject(i);
                if (task.getString("status").equals(status)) {
                    result.put(task);
                }
            }
        } catch (JSONException e) { /* ignore */ }
        return result;
    }
}
