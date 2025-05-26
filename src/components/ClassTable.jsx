export function renderAddress(addr) {
  if (!addr) return '-';
  if (addr === 'inline') return <span className="platform-address">inline</span>;
  return (
    <>
      <span className="platform-address">{addr}</span>{' '}
      <button
        className="copy-btn"
        onClick={() => {
          navigator.clipboard.writeText(addr);
          alert('Copied to clipboard');
        }}
      >
        📋
      </button>
    </>
  );
}

export default function ClassTable({ classData }) {
  return (
    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Type</th>
          <th>Arguments</th>
          <th>Windows</th>
          <th>macOS Intel</th>
          <th>macOS ARM</th>
          <th>iOS</th>
          <th>Android 32-bit</th>
          <th>Android 64-bit</th>
        </tr>
      </thead>
      <tbody>
        {classData.functions?.map(fn => (
          <tr key={fn.name}>
            <td>{fn.name}</td>
            <td className="type-info">Function</td>
            <td>{fn.args?.map(arg => arg.name || arg).join(', ')}</td>
            <td>{renderAddress(fn.bindings?.win)}</td>
            <td>{renderAddress(fn.bindings?.mac)}</td>
            <td>{renderAddress(fn.bindings?.m1)}</td>
            <td>{renderAddress(fn.bindings?.ios)}</td>
            <td>{renderAddress(fn.bindings?.android32)}</td>
            <td>{renderAddress(fn.bindings?.android64)}</td>
          </tr>
        ))}
        {classData.fields?.map(field => (
          <tr key={field.name}>
            <td>{field.name}</td>
            <td className="type-info">Field</td>
            <td></td>
            <td>{renderAddress(field.bindings?.win)}</td>
            <td>{renderAddress(field.bindings?.mac)}</td>
            <td>{renderAddress(field.bindings?.m1)}</td>
            <td>{renderAddress(field.bindings?.ios)}</td>
            <td>{renderAddress(field.bindings?.android32)}</td>
            <td>{renderAddress(field.bindings?.android64)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
