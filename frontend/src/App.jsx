import { ReactNode, useState } from 'react';

/**
 * Standard user authentication interface component.
 * @return {!ReactNode} The rendered login/signup box.
 */
export default function App() {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [message, setMessage] = useState('');
    const [isRegisterMode, setIsRegisterMode] = useState(false);

    const handleFormSubmit = async (e) => {
        e.preventDefault();
        setMessage('');

        const endpoint = isRegisterMode ? '/api/register' : '/api/login';

        try {
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({username, password}),
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || 'Authentication failed');
            }

            setMessage('Success: ' + data.message);
        } catch (error) {
            setMessage('Error: ' + error.message);
        }
    };

    return (
        <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center text-slate-800 p-6">
            <div className="w-full max-w-md bg-white border border-slate-200 rounded-2xl shadow-xl p-8 space-y-6">

                {/* Header section */}
                <div className="space-y-1 text-center">
                    <h2 className="text-2xl font-bold tracking-tight text-slate-900">
                        {isRegisterMode ? 'Create your account' : 'Sign in to your account'}
                    </h2>
                    <p className="text-sm text-slate-500">
                        {isRegisterMode ? 'Get started with our platform today.' : 'Welcome back! Please enter your details.'}
                    </p>
                </div>

                {/* Form input section */}
                <form onSubmit={handleFormSubmit} className="space-y-4 text-sm">
                    <div>
                        <label htmlFor="username" className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Username</label>
                        <input
                            id="username"
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            className="w-full bg-slate-50 border border-slate-300 rounded-lg px-4 py-2.5 text-slate-900 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition"
                            placeholder="Enter username"
                            required
                        />
                    </div>
                    <div>
                        <label htmlFor="password" className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Password</label>
                        <input
                            id="password"
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className="w-full bg-slate-50 border border-slate-300 rounded-lg px-4 py-2.5 text-slate-900 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition"
                            placeholder="••••••••"
                            required
                        />
                    </div>

                    <button type="submit" className="w-full bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-medium py-2.5 rounded-lg shadow transition-all cursor-pointer text-sm">
                        {isRegisterMode ? 'Sign up' : 'Sign in'}
                    </button>
                </form>

                {/* Mode toggle button */}
                <div className="text-center pt-2 text-sm">
                    <span className="text-slate-500">
                        {isRegisterMode ? 'Already have an account? ' : "Don't have an account? "}
                    </span>
                    <button
                        type="button"
                        onClick={() => {
                            setIsRegisterMode(!isRegisterMode);
                            setMessage('');
                            setUsername('');
                            setPassword('');
                        }}
                        className="text-blue-600 font-medium hover:text-blue-500 underline cursor-pointer"
                    >
                        {isRegisterMode ? 'Log in' : 'Sign up'}
                    </button>
                </div>

                {/* Response feedback messages */}
                {message && (
                    <div className={`p-3 rounded-lg border text-sm break-all ${
                        message.startsWith('Success')
                            ? 'bg-green-50 border-green-200 text-green-700'
                            : 'bg-red-50 border-red-200 text-red-700'
                    }`}>
                        {message}
                    </div>
                )}
            </div>
        </div>
    );
}