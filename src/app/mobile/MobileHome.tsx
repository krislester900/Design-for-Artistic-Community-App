// ... (code existant)

useEffect(() => {
  const timer = setTimeout(() => setIsDataLoading(false), 1500); // Mise à jour isDataLoading
  return () => clearTimeout(timer);
}, []);

<WelcomeBird zIndex="50" /> // Ajout de zIndex dans MobileHome

// ... (rest of the file)
