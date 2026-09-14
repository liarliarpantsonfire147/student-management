const formatGpa = (value) => value === null || value === undefined ? '—' : Number(value).toFixed(2);

export default function AdminSummary({ classes, students }) {
  const topStudents = [...students]
    .filter((student) => student.gpa !== null && student.gpa !== undefined)
    .sort((a, b) => Number(b.gpa) - Number(a.gpa))
    .slice(0, 5);
  const topClasses = [...classes]
    .filter((item) => item.average_gpa !== null && item.average_gpa !== undefined)
    .sort((a, b) => Number(b.average_gpa) - Number(a.average_gpa))
    .slice(0, 4);

  return <section className="mt-8 grid gap-5 lg:grid-cols-2">
    <div className="card overflow-hidden">
      <div className="border-b border-slate-100 p-6"><h2 className="font-bold">Top performers</h2><p className="mt-1 text-sm text-slate-500">Highest overall GPA across enrolled classes.</p></div>
      <div className="divide-y divide-slate-100">{topStudents.map((student, index) => <div className="flex items-center gap-4 p-4" key={student.student_id}><span className="w-5 text-sm font-bold text-slate-400">{index + 1}</span><div className="min-w-0 flex-1"><p className="truncate font-semibold">{student.full_name}</p><p className="text-sm text-slate-400">{student.class_count} classes · {student.year_group || 'Year not set'}</p></div><span className="font-bold">{formatGpa(student.gpa)}</span></div>)}{topStudents.length === 0 && <p className="p-6 text-sm text-slate-500">No graded students yet.</p>}</div>
    </div>
    <div className="card overflow-hidden">
      <div className="border-b border-slate-100 p-6"><h2 className="font-bold">Leading classes</h2><p className="mt-1 text-sm text-slate-500">Highest class average GPA.</p></div>
      <div className="divide-y divide-slate-100">{topClasses.map((item, index) => <div className="flex items-center gap-4 p-4" key={item.class_id}><span className="w-5 text-sm font-bold text-slate-400">{index + 1}</span><div className="min-w-0 flex-1"><p className="truncate font-semibold">{item.class_name}</p><p className="text-sm text-slate-400">{item.student_count} students · {item.graded_count} graded</p></div><span className="font-bold">{formatGpa(item.average_gpa)}</span></div>)}{topClasses.length === 0 && <p className="p-6 text-sm text-slate-500">No class averages yet.</p>}</div>
    </div>
  </section>;
}
