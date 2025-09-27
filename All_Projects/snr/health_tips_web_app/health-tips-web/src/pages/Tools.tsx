import { useState } from 'react'
import { ExternalHealthAPI, type NutritionInfo, type ExerciseRecommendation, type HealthNews } from '../services/externalHealthAPI'

export default function Tools() {
	const [activeTab, setActiveTab] = useState<'calculators' | 'nutrition' | 'exercise' | 'news'>('calculators')
	
	// BMI Calculator state
	const [bmiWeight, setBmiWeight] = useState('')
	const [bmiHeight, setBmiHeight] = useState('')
	const [bmiResult, setBmiResult] = useState<any>(null)
	
	// Calorie Calculator state
	const [calAge, setCalAge] = useState('')
	const [calGender, setCalGender] = useState('male')
	const [calWeight, setCalWeight] = useState('')
	const [calHeight, setCalHeight] = useState('')
	const [calActivity, setCalActivity] = useState('moderate')
	const [calResult, setCalResult] = useState<number | null>(null)
	
	// Nutrition state
	const [foodQuery, setFoodQuery] = useState('')
	const [nutritionInfo, setNutritionInfo] = useState<NutritionInfo | null>(null)
	const [nutritionLoading, setNutritionLoading] = useState(false)
	
	// Exercise state
	const [exerciseType, setExerciseType] = useState('')
	const [exercises, setExercises] = useState<ExerciseRecommendation[]>([])
	const [exerciseLoading, setExerciseLoading] = useState(false)
	
	// News state
	const [newsCategory, setNewsCategory] = useState('')
	const [healthNews, setHealthNews] = useState<HealthNews[]>([])
	const [newsLoading, setNewsLoading] = useState(false)

	// BMI Calculator
	const calculateBMI = () => {
		const weight = parseFloat(bmiWeight)
		const height = parseFloat(bmiHeight)
		
		if (weight && height) {
			const result = ExternalHealthAPI.calculateBMI(weight, height)
			setBmiResult(result)
		}
	}

	// Calorie Calculator
	const calculateCalories = () => {
		const age = parseInt(calAge)
		const weight = parseFloat(calWeight)
		const height = parseFloat(calHeight)
		
		if (age && weight && height) {
			const result = ExternalHealthAPI.calculateDailyCalories(age, calGender, weight, height, calActivity)
			setCalResult(result)
		}
	}

	// Get Nutrition Info
	const getNutritionInfo = async () => {
		if (!foodQuery.trim()) return
		
		setNutritionLoading(true)
		try {
			const info = await ExternalHealthAPI.getNutritionInfo(foodQuery)
			setNutritionInfo(info)
		} catch (err) {
			console.error('Failed to get nutrition info:', err)
		} finally {
			setNutritionLoading(false)
		}
	}

	// Get Exercise Recommendations
	const getExercises = async () => {
		setExerciseLoading(true)
		try {
			const recommendations = await ExternalHealthAPI.getExerciseRecommendations(exerciseType || undefined)
			setExercises(recommendations)
		} catch (err) {
			console.error('Failed to get exercises:', err)
		} finally {
			setExerciseLoading(false)
		}
	}

	// Get Health News
	const getNews = async () => {
		setNewsLoading(true)
		try {
			const news = await ExternalHealthAPI.getHealthNews(newsCategory || undefined)
			setHealthNews(news)
		} catch (err) {
			console.error('Failed to get news:', err)
		} finally {
			setNewsLoading(false)
		}
	}

	return (
		<div className="relative min-h-screen">
			{/* Floating decorative elements */}
			<div className="absolute inset-0 overflow-hidden pointer-events-none">
				<div className="absolute -top-40 -left-40 w-80 h-80 bg-gradient-to-br from-purple-200/20 to-pink-200/20 rounded-full blur-3xl"></div>
				<div className="absolute -bottom-40 -right-40 w-80 h-80 bg-gradient-to-tl from-blue-200/20 to-cyan-200/20 rounded-full blur-3xl"></div>
				<div className="absolute top-1/3 right-1/4 w-24 h-24 bg-gradient-to-r from-yellow-200/30 to-orange-200/30 rounded-full blur-2xl"></div>
			</div>

			<div className="relative z-10 mx-auto max-w-6xl p-4">
				<header className="text-center mb-12">
					<div className="card p-8 mb-8">
						<h1 className="text-5xl font-bold gradient-text mb-6">
							Health Tools & Calculators
						</h1>
						<p className="text-xl text-gray-600 max-w-3xl mx-auto leading-relaxed">
							Access powerful health calculators, nutrition information, exercise recommendations, and the latest health news.
						</p>
					</div>
				</header>

				{/* Tab Navigation */}
				<div className="flex flex-wrap justify-center gap-3 mb-12">
					{[
						{ id: 'calculators', name: 'Calculators', icon: '🧮' },
						{ id: 'nutrition', name: 'Nutrition', icon: '🥗' },
						{ id: 'exercise', name: 'Exercise', icon: '💪' },
						{ id: 'news', name: 'Health News', icon: '📰' }
					].map((tab) => (
						<button
							key={tab.id}
							onClick={() => setActiveTab(tab.id as any)}
							className={`px-8 py-4 rounded-xl font-medium transition-all duration-300 transform hover:scale-105 ${
								activeTab === tab.id
									? 'bg-gradient-to-r from-brand to-blue-600 text-white shadow-lg shadow-brand/30'
									: 'bg-white/80 hover:bg-white text-gray-700 shadow-md hover:shadow-lg'
							}`}
						>
							<span className="mr-3 text-xl">{tab.icon}</span>
							{tab.name}
						</button>
					))}
				</div>

				{/* Calculators Tab */}
				{activeTab === 'calculators' && (
					<div className="grid gap-8 md:grid-cols-2">
						{/* BMI Calculator */}
						<div className="card p-8">
							<h3 className="text-2xl font-bold mb-6 gradient-text">BMI Calculator</h3>
							<div className="space-y-6">
								<div>
									<label className="block text-sm font-semibold text-gray-700 mb-2">Weight (kg)</label>
									<input
										type="number"
										value={bmiWeight}
										onChange={(e) => setBmiWeight(e.target.value)}
										className="input"
										placeholder="70"
									/>
								</div>
								<div>
									<label className="block text-sm font-semibold text-gray-700 mb-2">Height (cm)</label>
									<input
										type="number"
										value={bmiHeight}
										onChange={(e) => setBmiHeight(e.target.value)}
										className="input"
										placeholder="170"
									/>
								</div>
								<button onClick={calculateBMI} className="btn w-full text-lg py-3">
									Calculate BMI
								</button>
								
								{bmiResult && (
									<div className="glass p-6 rounded-xl">
										<h4 className="font-bold text-gray-900 mb-3 text-lg">Your BMI: {bmiResult.bmi}</h4>
										<p className="text-gray-700 mb-2">Category: <span className="font-semibold">{bmiResult.category}</span></p>
										<p className="text-sm text-gray-600">{bmiResult.healthRisk}</p>
									</div>
								)}
							</div>
						</div>

						{/* Calorie Calculator */}
						<div className="card p-8">
							<h3 className="text-2xl font-bold mb-6 gradient-text">Daily Calorie Calculator</h3>
							<div className="space-y-6">
								<div className="grid grid-cols-2 gap-4">
									<div>
										<label className="block text-sm font-semibold text-gray-700 mb-2">Age</label>
										<input
											type="number"
											value={calAge}
											onChange={(e) => setCalAge(e.target.value)}
											className="input"
											placeholder="30"
										/>
									</div>
									<div>
										<label className="block text-sm font-semibold text-gray-700 mb-2">Gender</label>
										<select
											value={calGender}
											onChange={(e) => setCalGender(e.target.value)}
											className="input"
										>
											<option value="male">Male</option>
											<option value="female">Female</option>
										</select>
									</div>
								</div>
								<div className="grid grid-cols-2 gap-4">
									<div>
										<label className="block text-sm font-semibold text-gray-700 mb-2">Weight (kg)</label>
										<input
											type="number"
											value={calWeight}
											onChange={(e) => setCalWeight(e.target.value)}
											className="input"
											placeholder="70"
										/>
									</div>
									<div>
										<label className="block text-sm font-semibold text-gray-700 mb-2">Height (cm)</label>
										<input
											type="number"
											value={calHeight}
											onChange={(e) => setCalHeight(e.target.value)}
											className="input"
											placeholder="170"
										/>
									</div>
								</div>
								<div>
									<label className="block text-sm font-semibold text-gray-700 mb-2">Activity Level</label>
									<select
										value={calActivity}
										onChange={(e) => setCalActivity(e.target.value)}
										className="input"
									>
										<option value="sedentary">Sedentary (Little exercise)</option>
										<option value="light">Light (1-3 days/week)</option>
										<option value="moderate">Moderate (3-5 days/week)</option>
										<option value="active">Active (6-7 days/week)</option>
										<option value="very-active">Very Active (Hard exercise, physical job)</option>
									</select>
								</div>
								<button onClick={calculateCalories} className="btn w-full text-lg py-3">
									Calculate Calories
								</button>
								
								{calResult && (
									<div className="glass p-6 rounded-xl text-center">
										<h4 className="font-bold text-gray-900 mb-3 text-lg">Daily Calorie Needs</h4>
										<p className="text-4xl font-bold gradient-text">{calResult}</p>
										<p className="text-sm text-gray-600">calories per day</p>
									</div>
								)}
							</div>
						</div>
					</div>
				)}

				{/* Nutrition Tab */}
				{activeTab === 'nutrition' && (
					<div className="card p-8">
						<h3 className="text-2xl font-bold mb-6 gradient-text">Nutrition Information</h3>
						<div className="max-w-md mb-8">
							<div className="flex gap-3">
								<input
									type="text"
									value={foodQuery}
									onChange={(e) => setFoodQuery(e.target.value)}
									placeholder="Enter food name (e.g., apple, chicken breast)"
									className="input flex-1 text-lg"
								/>
								<button 
									onClick={getNutritionInfo}
									disabled={nutritionLoading || !foodQuery.trim()}
									className="btn px-6"
								>
									{nutritionLoading ? 'Loading...' : 'Search'}
								</button>
							</div>
						</div>

						{nutritionInfo && (
							<div className="glass p-8 rounded-2xl">
								<h4 className="text-3xl font-bold text-gray-900 mb-6">{nutritionInfo.food}</h4>
								<div className="grid gap-8 md:grid-cols-2">
									<div>
										<h5 className="font-semibold text-gray-900 mb-4 text-lg">Macronutrients (per serving)</h5>
										<div className="space-y-3">
											<div className="flex justify-between items-center p-3 bg-white/50 rounded-lg">
												<span className="font-medium">Calories:</span>
												<span className="font-bold text-brand">{nutritionInfo.calories} kcal</span>
											</div>
											<div className="flex justify-between items-center p-3 bg-white/50 rounded-lg">
												<span className="font-medium">Protein:</span>
												<span className="font-bold text-brand">{nutritionInfo.protein}g</span>
											</div>
											<div className="flex justify-between items-center p-3 bg-white/50 rounded-lg">
												<span className="font-medium">Carbohydrates:</span>
												<span className="font-bold text-brand">{nutritionInfo.carbs}g</span>
											</div>
											<div className="flex justify-between items-center p-3 bg-white/50 rounded-lg">
												<span className="font-medium">Fat:</span>
												<span className="font-bold text-brand">{nutritionInfo.fat}g</span>
											</div>
											<div className="flex justify-between items-center p-3 bg-white/50 rounded-lg">
												<span className="font-medium">Fiber:</span>
												<span className="font-bold text-brand">{nutritionInfo.fiber}g</span>
											</div>
										</div>
									</div>
									<div>
										<h5 className="font-semibold text-gray-900 mb-4 text-lg">Vitamins & Minerals</h5>
										<div className="flex flex-wrap gap-3">
											{nutritionInfo.vitamins.map((vitamin, index) => (
												<span key={index} className="px-4 py-2 bg-gradient-to-r from-brand/10 to-blue-600/10 text-brand rounded-full text-sm font-semibold border border-brand/20">
													{vitamin}
												</span>
											))}
										</div>
									</div>
								</div>
							</div>
						)}
					</div>
				)}

				{/* Exercise Tab */}
				{activeTab === 'exercise' && (
					<div className="card p-8">
						<h3 className="text-2xl font-bold mb-6 gradient-text">Exercise Recommendations</h3>
						<div className="max-w-md mb-8">
							<div className="flex gap-3">
								<select
									value={exerciseType}
									onChange={(e) => setExerciseType(e.target.value)}
									className="input flex-1"
								>
									<option value="">All Types</option>
									<option value="cardio">Cardio</option>
									<option value="strength">Strength</option>
									<option value="flexibility">Flexibility</option>
									<option value="balance">Balance</option>
								</select>
								<button 
									onClick={getExercises}
									disabled={exerciseLoading}
									className="btn px-6"
								>
									{exerciseLoading ? 'Loading...' : 'Get Exercises'}
								</button>
							</div>
						</div>

						{exercises.length > 0 && (
							<div className="grid gap-6 md:grid-cols-2">
								{exercises.map((exercise, index) => (
									<div key={index} className="glass p-6 rounded-xl hover:shadow-xl transition-all duration-300">
										<h5 className="text-xl font-bold text-gray-900 mb-3">{exercise.name}</h5>
										<div className="space-y-3 text-sm mb-4">
											<div className="flex items-center gap-2">
												<span className="text-gray-600">Type:</span>
												<span className="px-3 py-1 bg-gradient-to-r from-brand/10 to-blue-600/10 text-brand rounded-full text-xs font-semibold border border-brand/20">
													{exercise.type}
												</span>
											</div>
											<div className="flex items-center gap-2">
												<span className="text-gray-600">Duration:</span>
												<span className="font-semibold">{exercise.duration}</span>
											</div>
											<div className="flex items-center gap-2">
												<span className="text-gray-600">Intensity:</span>
												<span className="font-semibold">{exercise.intensity}</span>
											</div>
										</div>
										<div className="mb-4">
											<h6 className="font-semibold text-gray-900 mb-2">Benefits:</h6>
											<ul className="text-sm text-gray-600 space-y-1">
												{exercise.benefits.map((benefit, idx) => (
													<li key={idx} className="flex items-start gap-2">
														<span className="text-brand text-lg">•</span>
														{benefit}
													</li>
												))}
											</ul>
										</div>
										<div>
											<h6 className="font-semibold text-gray-900 mb-2">Instructions:</h6>
											<p className="text-sm text-gray-600">{exercise.instructions}</p>
										</div>
									</div>
								))}
							</div>
						)}
					</div>
				)}

				{/* News Tab */}
				{activeTab === 'news' && (
					<div className="card p-8">
						<h3 className="text-2xl font-bold mb-6 gradient-text">Latest Health News</h3>
						<div className="max-w-md mb-8">
							<div className="flex gap-3">
								<select
									value={newsCategory}
									onChange={(e) => setNewsCategory(e.target.value)}
									className="input flex-1"
								>
									<option value="">All Categories</option>
									<option value="nutrition">Nutrition</option>
									<option value="exercise">Exercise</option>
									<option value="mental-health">Mental Health</option>
									<option value="sleep">Sleep</option>
								</select>
								<button 
									onClick={getNews}
									disabled={newsLoading}
									className="btn px-6"
								>
									{newsLoading ? 'Loading...' : 'Get News'}
								</button>
							</div>
						</div>

						{healthNews.length > 0 && (
							<div className="space-y-6">
								{healthNews.map((news, index) => (
									<div key={index} className="glass p-6 rounded-xl hover:shadow-xl transition-all duration-300">
										<h5 className="text-xl font-bold text-gray-900 mb-3">{news.title}</h5>
										<p className="text-gray-600 mb-4 text-lg leading-relaxed">{news.summary}</p>
										<div className="flex items-center justify-between text-sm text-gray-500 mb-3">
											<span className="bg-white/50 px-3 py-1 rounded-full">Source: {news.source}</span>
											<span className="bg-white/50 px-3 py-1 rounded-full">{new Date(news.publishedAt).toLocaleDateString()}</span>
										</div>
										<div>
											<span className="px-3 py-1 bg-gradient-to-r from-brand/10 to-blue-600/10 text-brand rounded-full text-xs font-semibold border border-brand/20">
												{news.category.replace('-', ' ')}
											</span>
										</div>
									</div>
								))}
							</div>
						)}
					</div>
				)}
			</div>
		</div>
	)
}
